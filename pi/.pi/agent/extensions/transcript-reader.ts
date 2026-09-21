import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  matchesKey,
  stripTerminalSequences,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

type TuiLike = {
  terminal?: { rows?: number };
  requestRender: () => void;
};

type Done = (value: void) => void;

type Mode = "normal" | "search";

class TranscriptReader {
  private offset = 0;
  private mode: Mode = "normal";
  private query = "";
  private matches: number[] = [];
  private matchIndex = -1;
  private pendingG = false;
  private cachedWidth = 0;
  private cachedOffset = -1;
  private cachedQuery = "";
  private cachedLines: string[] = [];
  private displayWidth = 0;
  private displayLines: string[] = [];
  private initialOffsetSet = false;

  constructor(
    private readonly tui: TuiLike,
    private readonly theme: any,
    private readonly done: Done,
    private readonly sourceLines: string[],
    private readonly title: string,
  ) {}

  handleInput(data: string): void {
    if (this.mode === "search") {
      this.handleSearchInput(data);
      this.tui.requestRender();
      return;
    }

    if (data !== "g") this.pendingG = false;

    if (data === "q" || data === "Q" || matchesKey(data, "escape")) {
      this.done();
      return;
    }

    if (data === "j" || matchesKey(data, "down")) this.scroll(1);
    else if (data === "k" || matchesKey(data, "up")) this.scroll(-1);
    else if (matchesKey(data, "ctrl+d") || matchesKey(data, "pageDown"))
      this.scroll(this.pageSize());
    else if (matchesKey(data, "ctrl+u") || matchesKey(data, "pageUp"))
      this.scroll(-this.pageSize());
    else if (matchesKey(data, "home")) this.goTop();
    else if (matchesKey(data, "end") || data === "G") this.goBottom();
    else if (data === "g") this.handleG();
    else if (data === "/") this.startSearch();
    else if (data === "n") this.nextMatch(1);
    else if (data === "N") this.nextMatch(-1);

    this.tui.requestRender();
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(width: number): string[] {
    if (
      this.cachedWidth === width &&
      this.cachedOffset === this.offset &&
      this.cachedQuery === this.query
    ) {
      return this.cachedLines;
    }

    const displayLines = this.getDisplayLines(width);
    if (!this.initialOffsetSet) {
      this.offset = this.lastPromptOffset(displayLines, width);
      this.initialOffsetSet = true;
    }

    const height = this.height();
    const bodyHeight = Math.max(1, height - 2);
    const maxOffset = this.maxOffset(width);
    const percent =
      displayLines.length <= bodyHeight
        ? "all"
        : `${Math.round((this.offset / Math.max(1, maxOffset)) * 100)}%`;
    const search = this.query
      ? ` • /${this.query}${this.matches.length ? ` [${this.matchIndex + 1}/${this.matches.length}]` : " [0]"}`
      : "";

    const header = this.pad(
      this.theme.fg("accent", ` Transcript Reader: ${this.title}`) +
        this.theme.fg(
          "dim",
          ` • ${this.offset + 1}-${Math.min(this.offset + bodyHeight, displayLines.length)}/${displayLines.length} • ${percent}${search}`,
        ),
      width,
    );
    const footerText =
      this.mode === "search"
        ? `/${this.query}`
        : "j/k scroll • Ctrl-d/u page • gg/G top/bottom • / search • n/N next/prev • q close";
    const footer = this.pad(this.theme.fg("dim", ` ${footerText}`), width);

    const body = displayLines
      .slice(this.offset, this.offset + bodyHeight)
      .map((line, i) => this.decorateLine(line, this.offset + i, width));

    while (body.length < bodyHeight) body.push(" ".repeat(width));

    this.cachedWidth = width;
    this.cachedOffset = this.offset;
    this.cachedQuery = this.query;
    this.cachedLines = [header, ...body, footer];
    return this.cachedLines;
  }

  private handleSearchInput(data: string): void {
    if (matchesKey(data, "escape")) {
      this.mode = "normal";
      return;
    }
    if (matchesKey(data, "enter")) {
      this.mode = "normal";
      this.recomputeMatches(true);
      return;
    }
    if (matchesKey(data, "backspace")) {
      this.query = this.query.slice(0, -1);
      this.recomputeMatches(true);
      return;
    }
    if (data.length === 1 && data >= " " && data !== "\x7f") {
      this.query += data;
      this.recomputeMatches(true);
    }
  }

  private startSearch(): void {
    this.mode = "search";
    this.query = "";
    this.matches = [];
    this.matchIndex = -1;
  }

  private recomputeMatches(jump: boolean): void {
    const needle = this.query.toLowerCase();
    const lines = this.displayLines.length
      ? this.displayLines
      : this.sourceLines;
    this.matches = needle
      ? lines.flatMap((line, index) =>
          line.toLowerCase().includes(needle) ? [index] : [],
        )
      : [];
    if (jump && this.matches.length > 0) {
      const firstAfterOffset = this.matches.findIndex(
        (line) => line >= this.offset,
      );
      this.matchIndex = firstAfterOffset >= 0 ? firstAfterOffset : 0;
      this.offset = this.matches[this.matchIndex] ?? this.offset;
    }
  }

  private nextMatch(direction: 1 | -1): void {
    if (!this.query || this.matches.length === 0) return;
    if (this.matchIndex < 0) this.matchIndex = 0;
    else
      this.matchIndex =
        (this.matchIndex + direction + this.matches.length) %
        this.matches.length;
    this.offset = this.matches[this.matchIndex] ?? this.offset;
  }

  private handleG(): void {
    if (this.pendingG) {
      this.goTop();
      this.pendingG = false;
    } else {
      this.pendingG = true;
    }
  }

  private decorateLine(line: string, lineIndex: number, width: number): string {
    const isMatch = this.matches.includes(lineIndex);
    const prefix = isMatch ? this.theme.fg("accent", "> ") : "  ";
    return this.pad(prefix + this.styleLine(line), width);
  }

  private styleLine(line: string): string {
    if (line === "## USER")
      return this.theme.fg("userMessageText", this.theme.bold(line));
    if (line === "## ASSISTANT")
      return this.theme.fg("accent", this.theme.bold(line));
    if (line.startsWith("## "))
      return this.theme.fg("muted", this.theme.bold(line));
    if (line.startsWith("_Showing ")) return this.theme.fg("dim", line);
    if (line.startsWith("````") || line.startsWith("```"))
      return this.theme.fg("mdCodeBlockBorder", line);
    return line;
  }

  private scroll(delta: number): void {
    this.offset = Math.min(
      this.maxOffset(this.cachedWidth || this.displayWidth || 80),
      Math.max(0, this.offset + delta),
    );
  }

  private lastPromptOffset(lines: string[], width: number): number {
    const index = lines.findLastIndex((line) => {
      const plain = stripTerminalSequences(line).trim();
      return plain === "## USER" || plain === "USER";
    });
    return Math.min(this.maxOffset(width), Math.max(0, index));
  }

  private goTop(): void {
    this.offset = 0;
  }

  private goBottom(): void {
    this.offset = this.maxOffset(this.cachedWidth || this.displayWidth || 80);
  }

  private maxOffset(width: number): number {
    return Math.max(
      0,
      this.getDisplayLines(width).length - Math.max(1, this.height() - 2),
    );
  }

  private pageSize(): number {
    return Math.max(1, Math.floor((this.height() - 2) / 2));
  }

  private height(): number {
    return Math.max(8, (this.tui.terminal?.rows ?? 30) - 2);
  }

  private pad(text: string, width: number): string {
    const truncated = truncateToWidth(text, width, "");
    return truncated + " ".repeat(Math.max(0, width - visibleWidth(truncated)));
  }

  private getDisplayLines(width: number): string[] {
    const contentWidth = Math.max(1, width - 2);
    if (this.displayWidth === contentWidth && this.displayLines.length > 0)
      return this.displayLines;

    this.displayWidth = contentWidth;
    this.displayLines = this.sourceLines.flatMap((line) => {
      if (line === "") return [""];
      return wrapTextWithAnsi(line, contentWidth);
    });
    return this.displayLines;
  }
}

function buildTranscriptLines(
  ctx: { sessionManager: any },
  options: { promptLimit?: number; includeToolDetails?: boolean } = {},
): string[] {
  const allEntries =
    ctx.sessionManager.buildContextEntries?.() ??
    ctx.sessionManager.getBranch?.() ??
    [];
  const entries = options.promptLimit
    ? entriesFromLastPrompts(allEntries, options.promptLimit)
    : allEntries;
  const lines: string[] = [];

  if (options.promptLimit) {
    const plural = options.promptLimit === 1 ? "prompt" : "prompts";
    lines.push(
      `_Showing final responses for last ${options.promptLimit} ${plural}. Use /transcript <n> to show more, or /transcript all for the full transcript._`,
      "",
    );
  }

  for (const entry of entries) {
    if (entry.type === "message") {
      appendMessage(lines, entry.message, options.includeToolDetails ?? false);
    } else if (options.includeToolDetails && entry.type === "compaction") {
      appendBlock(lines, "COMPACTION", entry.summary ?? "");
    } else if (options.includeToolDetails && entry.type === "branch_summary") {
      appendBlock(lines, "BRANCH SUMMARY", entry.summary ?? "");
    } else if (options.includeToolDetails && entry.type === "model_change") {
      lines.push(`--- model: ${entry.provider}/${entry.modelId} ---`, "");
    } else if (
      options.includeToolDetails &&
      entry.type === "thinking_level_change"
    ) {
      lines.push(`--- thinking: ${entry.thinkingLevel} ---`, "");
    } else if (options.includeToolDetails && entry.type === "custom_message") {
      appendBlock(
        lines,
        `CUSTOM:${entry.customType}`,
        contentToText(entry.content, true),
      );
    }
  }

  return lines.length ? lines : ["No transcript entries yet."];
}

function entriesFromLastPrompts(entries: any[], promptLimit: number): any[] {
  const promptIndexes = entries
    .map((entry, index) =>
      entry.type === "message" && entry.message?.role === "user" ? index : -1,
    )
    .filter((index) => index >= 0);

  if (promptIndexes.length <= promptLimit) return entries;
  return entries.slice(promptIndexes[promptIndexes.length - promptLimit]!);
}

function appendMessage(
  lines: string[],
  message: any,
  includeToolDetails: boolean,
): void {
  if (!message) return;
  if (message.role === "user")
    appendBlock(lines, "USER", contentToText(message.content, false));
  else if (message.role === "assistant")
    appendBlock(
      lines,
      "ASSISTANT",
      contentToText(message.content, includeToolDetails),
    );
  else if (includeToolDetails && message.role === "toolResult")
    appendBlock(
      lines,
      `TOOL RESULT: ${message.toolName ?? message.toolCallId}`,
      contentToText(message.content, true),
    );
  else if (includeToolDetails && message.role === "bashExecution")
    appendBlock(
      lines,
      "BASH",
      `$ ${message.command ?? ""}\n${message.output ?? ""}`,
    );
  else if (includeToolDetails && message.role === "custom")
    appendBlock(
      lines,
      `CUSTOM:${message.customType}`,
      contentToText(message.content, true),
    );
  else if (includeToolDetails && message.role === "branchSummary")
    appendBlock(lines, "BRANCH SUMMARY", message.summary ?? "");
  else if (includeToolDetails && message.role === "compactionSummary")
    appendBlock(lines, "COMPACTION", message.summary ?? "");
}

function appendBlock(lines: string[], label: string, text: string): void {
  lines.push(`## ${label}`);
  appendMarkdownLikeLines(lines, text);
  lines.push("");
}

function appendMarkdownLikeLines(lines: string[], text: string): void {
  lines.push(...text.split("\n"));
}

function contentToText(content: any, includeToolDetails: boolean): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((part) => {
      if (part?.type === "text") return part.text ?? "";
      if (includeToolDetails && part?.type === "thinking")
        return `[thinking]\n${part.thinking ?? ""}`;
      if (includeToolDetails && part?.type === "toolCall")
        return `[tool call: ${part.name}]\n${JSON.stringify(part.arguments ?? {}, null, 2)}`;
      if (includeToolDetails && part?.type === "image")
        return `[image: ${part.mimeType ?? "unknown"}]`;
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

function wrapLines(lines: string[], width: number): string[] {
  const out: string[] = [];
  for (const line of lines) {
    if (line === "") {
      out.push("");
      continue;
    }
    if (line.includes("\x1b")) {
      out.push(line);
      continue;
    }
    let rest = line;
    while (visibleWidth(rest) > width) {
      out.push(truncateToWidth(rest, width, ""));
      rest = rest.slice(out[out.length - 1]!.length);
    }
    out.push(rest);
  }
  return out;
}

async function renderWithGlow(
  pi: ExtensionAPI,
  markdownLines: string[],
): Promise<string[]> {
  const directory = await mkdtemp(join(tmpdir(), "pi-transcript-"));
  const file = join(directory, "transcript.md");
  const width = Math.max(20, (process.stdout.columns ?? 100) - 4);

  try {
    await writeFile(file, markdownLines.join("\n"), "utf8");
    const result = await pi.exec("glow", [
      "--pager=false",
      "--style=auto",
      "--preserve-new-lines",
      `--width=${width}`,
      file,
    ]);
    if (result.code !== 0)
      throw new Error(
        result.stderr.trim() || `glow exited with code ${result.code}`,
      );
    return result.stdout.replace(/\n$/, "").split("\n");
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function parseTranscriptArgs(args: string): {
  showAll: boolean;
  promptLimit: number;
  includeToolDetails: boolean;
} {
  const trimmed = args.trim();
  const showAll = /^(all|--all|-a)$/i.test(trimmed);
  if (showAll)
    return { showAll: true, promptLimit: 1, includeToolDetails: true };

  const promptLimit = Math.max(
    1,
    Math.min(50, Number.parseInt(trimmed || "1", 10) || 1),
  );
  return { showAll: false, promptLimit, includeToolDetails: false };
}

export default function (pi: ExtensionAPI) {
  async function openTranscript(ctx: any, args = ""): Promise<void> {
    if (ctx.mode !== "tui") {
      ctx.ui.notify(
        "Transcript reader is only available in TUI mode.",
        "warning",
      );
      return;
    }

    const parsed = parseTranscriptArgs(args);
    const markdownLines = buildTranscriptLines(ctx, {
      promptLimit: parsed.showAll ? undefined : parsed.promptLimit,
      includeToolDetails: parsed.includeToolDetails,
    });
    let sourceLines: string[];
    try {
      sourceLines = await renderWithGlow(pi, markdownLines);
    } catch (error) {
      ctx.ui.notify(
        `Glow rendering failed; using plain text: ${error instanceof Error ? error.message : String(error)}`,
        "warning",
      );
      sourceLines = markdownLines;
    }
    const sessionTitle =
      ctx.sessionManager.getSessionName?.() ??
      ctx.sessionManager.getSessionId?.() ??
      "current session";
    const plural = parsed.promptLimit === 1 ? "prompt" : "prompts";
    const title = parsed.showAll
      ? `${sessionTitle} (all)`
      : `${sessionTitle} (last ${parsed.promptLimit} ${plural})`;

    await ctx.ui.custom<void>(
      (tui: TuiLike, theme: unknown, _keybindings: unknown, done: Done) =>
        new TranscriptReader(tui, theme, done, sourceLines, title),
      {
        overlay: true,
        overlayOptions: {
          width: "100%",
          maxHeight: "100%",
          anchor: "center",
        },
      },
    );
  }

  pi.registerCommand("transcript", {
    description:
      "Open a read-only Vim-style transcript reader. Default: last prompt. Use /transcript <n> or /transcript all.",
    handler: async (args, ctx) => openTranscript(ctx, args),
  });

  pi.registerShortcut("ctrl+r", {
    description: "Open transcript reader for the last prompt",
    handler: async (ctx) => openTranscript(ctx),
  });
}
