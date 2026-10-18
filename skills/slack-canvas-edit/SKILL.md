---
name: slack-canvas-edit
description: Use when reading, reviewing, or editing a Slack canvas through the Slack MCP tools (slack_read_canvas, slack_update_canvas), and always when a canvas read or update result is too large and the harness saves it to a file instead. Covers reading the canvas once, splitting an oversized result into per-section files with the `canvas-split` helper, editing by section ID, and checking the edit without reading the canvas again.
---

# Reading and editing Slack canvases

Large canvases (a long spec, say) overflow the tool output limit. `slack_read_canvas` then fails with `result (N characters across 1 line) exceeds maximum allowed tokens`, and the harness saves the full result to a file whose path appears in the error. The helper `canvas-split` turns that file into something you can read piece by piece, so you never need to write a parser mid-session.

## Read the canvas once

Call `slack_read_canvas` once per task. The section IDs it returns are still valid when you apply the edit: we checked an update against a 90-section canvas and every ID survived, with new sections getting new IDs. Each `slack_update_canvas` response also carries a fresh `section_id_mapping` for the whole canvas, so after your first edit you already hold the newest mapping without asking for it.

Read again only when a teammate may have edited the canvas since your read, either because the user says so or because a long time has passed. A `replace` overwrites the whole section, so a stale copy would erase their change. If an update fails with an unknown section ID, read again.

## When the read overflows

Take the file path from the error and split it into your scratchpad:

```sh
canvas-split <saved-result-file> <scratchpad>/canvas-<canvas_id>
```

It prints an outline with one line per section: number, section ID, first line indented under its heading, size in characters, and the count of open comment threads. It writes:

- `sections/NNN.md`, one file per section in document order, with the exact text Slack holds
- `index.tsv` with number, section ID, size, comment count, heading path, and first line
- `canvas.md`, the full markdown (read results only)
- `meta.json` with `canvas_id`, `canvas_url`, and `comment_threads`

From there, use the Grep tool on `sections/` to find text, and the Read tool on only the sections you need. Do not write `python3 -c`, `jq`, or `sed` against the saved file, and do not open `canvas.md` whole, because that just brings the overflow back.

For comments, `meta.json` lists each thread's `section_id`, `channel_id`, and `thread_ts`. Read one with `slack_read_thread`.

## How sections work

A section is a heading, a paragraph, or a whole list or table. Changing one bullet means sending a `replace` for the whole list section with that bullet edited, so start from the section file's exact text and change only what you mean to. A heading is a section of its own, separate from the body under it. The first section is the canvas title and takes a single line only.

Put all edits in one `slack_update_canvas` call with the `sections` array, written directly in the tool call. Do not build an `ops.json` with a script first. Each entry takes `edit_type` (`replace`, `append`, `prepend`, or `delete`), `section_id`, and `content`. The field names are not `action` or `markdown`:

```json
{"canvas_id": "F0BRSMNKFAL", "sections": [
  {"edit_type": "replace", "section_id": "temp:C:UZM…", "content": "* first bullet\n* edited bullet\n"}
]}
```

## Check the edit without reading again

The update response holds the new `section_id_mapping`.

- If it fits inline, confirm the edited sections show the new text.
- If it overflows, run `canvas-split` on the saved response into the same directory. It replaces `sections/` and drops `canvas.md`, because the update response has no full markdown. Then use the Grep tool for a distinctive phrase from each edit.

Use that new mapping for any further edits, and share `canvas_url` with the user at the end.

## Small canvases

The same rules apply when the read fits inline. The mapping is already in context, so reuse it for every update in the task instead of reading the canvas before each one.
