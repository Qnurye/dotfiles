---
name: copywriting
description: Guidelines for writing UI copy including buttons, titles, error messages, and placeholders. Use when writing user-facing text, creating new UI components, or reviewing copy for consistency.
---

# Copywriting Guidelines

Modern, friendly, and clear copy for a design tool built for everyone.

## Core Principles

1. **Sentence case everywhere** — Titles, buttons, labels, headings all use sentence case
2. **Action-oriented** — Lead with verbs, focus on what users can do
3. **Concise** — Every word earns its place; cut ruthlessly
4. **Friendly, not casual** — Approachable but professional
5. **Jargon-free** — This is a tool for non-designers; keep it accessible

## Voice and Pronouns

### Default: Omit pronouns

Most UI copy works best without pronouns — it's cleaner and more direct.

| Context      | ✅ Preferred    | ❌ Avoid                               |
| ------------ | --------------- | -------------------------------------- |
| Buttons      | "Save changes"  | "Save your changes"                    |
| Labels       | "Email address" | "Your email address"                   |
| Placeholders | "Enter email"   | "Enter your email" (except auth forms) |
| Headings     | "Files"         | "Your files"                           |
| Settings     | "Notifications" | "Your notifications"                   |

### When to use "you" / "your"

Use when **clarity requires it** or to **create warmth** in key moments:

- **Onboarding**: "Create your first file"
- **Empty states**: "No files yet. Create your first file to get started."
- **Permissions**: "Only you can see this" / "Shared with you"
- **Possessive clarity**: "Your account" (vs team account)
- **Confirmations**: "Your file has been deleted"

### When to use "we"

Use sparingly — only when the product/team is genuinely acting:

- **System actions**: "We'll send you a verification email"
- **Policies**: "We never share your data"
- **Errors caused by system**: "We couldn't connect to the server"

Avoid "we" when the user is acting:

- ❌ "We've saved your file" → ✅ "File saved"
- ❌ "We've created your account" → ✅ "Account created"

### Summary

| Pronoun    | When to use                                          |
| ---------- | ---------------------------------------------------- |
| (none)     | Default for most UI elements                         |
| "You/your" | Onboarding, empty states, permissions, confirmations |
| "We"       | System actions, policies, system-caused errors       |

## Capitalization

Use **sentence case** for all UI text:

| Element     | ✅ Correct           | ❌ Incorrect         |
| ----------- | -------------------- | -------------------- |
| Page titles | "Create new file"    | "Create New File"    |
| Buttons     | "Save changes"       | "Save Changes"       |
| Menu items  | "Export as PDF"      | "Export As PDF"      |
| Tab labels  | "Recent files"       | "Recent Files"       |
| Headings    | "Workspace settings" | "Workspace Settings" |
| Tooltips    | "Add a new layer"    | "Add A New Layer"    |

**Exceptions:**

- Proper nouns: "Share to Google Drive"
- Acronyms: "Export as PDF", "AI assistant"
- Product name: "Voyager"

## Buttons

### Primary actions

- Use clear, specific verbs: "Create file", "Send invitation", "Save changes"
- Avoid vague labels: ❌ "Submit", "OK", "Done"

### Examples

| Context         | ✅ Correct            | ❌ Incorrect          |
| --------------- | --------------------- | --------------------- |
| Form submission | "Create account"      | "Submit"              |
| Save action     | "Save changes"        | "Save" (if ambiguous) |
| Cancel          | "Cancel"              | "Nevermind"           |
| Confirm delete  | "Delete file"         | "Yes, delete"         |
| Auth            | "Sign in" / "Sign up" | "Login" / "Signup"    |

## Titles and Headings

- Use sentence case
- Be specific about context: "Edit workspace settings" not just "Settings"
- For modals, state the action: "Share file", "Delete workspace"

## Error Messages

Guidelines for **UI error copy** (toasts, alerts, inline messages). Does not apply to `Error#message` in code.

### Structure

1. **What happened** — Brief, clear statement
2. **Why** (if helpful) — Context that helps understanding
3. **What to do** — Actionable next step

### Examples

```
✅ "Couldn't save changes. Check your connection and try again."
✅ "This email is already registered. Try signing in instead."

❌ "Error 500: Internal server error"
❌ "Invalid input"
```

### Tone

- Never blame the user
- Be helpful, not apologetic (avoid "Sorry, but…")
- Offer solutions when possible

## Empty States

Guide users toward action:

```
✅ "No files yet. Create your first file to get started."
✅ "No results found. Try a different search term."

❌ "No data"
❌ "Empty"
```

## Placeholder Text

### When to use

- **Simple/single fields** (search bar, quick input): Use placeholder with verb
- **Forms with multiple fields**: Skip placeholders, rely on labels instead

Placeholders disappear when typing — labels are always visible and more accessible.

### Rules

- Start with a verb: "Enter", "Search", "Select", "Start", "Add", "Type"
- Omit pronouns by default
- **Exception**: Use "your" for sign in/sign up forms (onboarding warmth)
- Use sentence case, no period
- No example data like "name@example.com"

### Ellipsis in placeholders

- **Use ellipsis** for open-ended input (search, writing, comments) — invites exploration
- **No ellipsis** for structured data (email, URL, name) — expects specific value

### Examples

| Context          | ✅ Correct         | ❌ Avoid              |
| ---------------- | ------------------ | --------------------- |
| Search bar       | "Search files…"    | "Search"              |
| Text editor      | "Start writing…"   | "Write here"          |
| Comment field    | "Add a comment…"   | "Comment"             |
| Email input      | "Enter email"      | "name@example.com"    |
| URL field        | "Enter URL"        | "https://example.com" |
| Dropdown         | "Select option"    | "Choose…"             |
| Sign in/sign up  | "Enter your email" | "name@example.com"    |
| Multi-field form | (use labels)       | "Enter name"          |

## Tooltips

- One short sentence or phrase
- Explain what happens, not what it is
- No period unless multiple sentences

```
✅ "Add a text layer"
✅ "Undo last action"

❌ "Text Tool"
❌ "Click here to add text to your design canvas"
```

## Confirmation Dialogs

### Structure

- **Title**: Action being confirmed ("Delete file")
- **Body**: Consequence, one sentence
- **Primary button**: Matches the action ("Delete")
- **Secondary button**: "Cancel"

### Example

```
Title: Delete "My Design"
Body: This file will be permanently deleted. This action cannot be undone.
Buttons: [Cancel] [Delete]
```

## Word Choice

### Preferred terms

| Use              | Instead of                        |
| ---------------- | --------------------------------- |
| "File"           | "Document", "Project"             |
| "Create"         | "Add", "New" (as verbs)           |
| "Delete"         | "Remove" (for permanent actions)  |
| "Remove"         | "Delete" (for reversible actions) |
| "Sign in" (verb) | "Login", "Log in"                 |
| "Sign up" (verb) | "Signup", "Register"              |
| "Settings"       | "Preferences", "Options"          |
| "Learn more"     | "Click here", "Read more"         |
| "Name"           | "Profile name"                    |

Note: Use "Name" when context is clear (e.g., under "Profile" section). When ambiguous, use "Your name" (for user's own) or "Their name" (for others). Avoid "Full name".

### "Please"

**Use "please" when:**

- User is asked to wait or do something inconvenient
- Software caused the problem

```
✅ "Please wait a moment…"
✅ "Something went wrong. Please try again."
✅ "Please wait while we process your request."
✅ "Sign in failed. Please check your email and password."
```

**Omit "please" for routine actions:**

```
❌ "Please enter your email"  →  ✅ "Enter your email"
❌ "Please select an option"  →  ✅ "Select an option"
```

### Avoid

- "Successfully" ("File saved" not "File successfully saved")
- "Simply" / "Just" / "Easy" (patronizing)
- Technical jargon unless necessary

## Punctuation

### Periods

| Element                       | Period? | Example                                   |
| ----------------------------- | ------- | ----------------------------------------- |
| Buttons                       | No      | "Save changes"                            |
| Labels                        | No      | "Email address"                           |
| Headings                      | No      | "Workspace settings"                      |
| Tooltips (single sentence)    | No      | "Add a text layer"                        |
| Tooltips (multiple sentences) | Yes     | "Add a text layer. Drag to resize."       |
| Placeholders                  | No      | "Enter email"                             |
| Menu items                    | No      | "Export as PDF"                           |
| Error messages                | Yes     | "Password must be at least 8 characters." |
| Descriptions                  | Yes     | "This file will be permanently deleted."  |
| Empty states                  | Yes     | "No files yet. Create your first file."   |
| Aria labels                   | No      | "Close dialog"                            |

### Ellipsis

Always use the ellipsis character (…) instead of three periods (...).

**When to use:**

- Loading/processing states: "Saving…", "Creating…"
- Open-ended placeholders: "Search files…", "Type a message…"

### Quotes

**When to use quotes:**

- File/item names in messages: Delete "My Design"?
- User-generated content in UI: Rename to "Untitled"
- Referencing UI elements in help text: Click "Save"

**Curly vs straight quotes:**

| Context                    | Use                   | Example              |
| -------------------------- | --------------------- | -------------------- |
| UI copy (visible to users) | Curly quotes "" ''    | Delete "My Design"   |
| Code, attributes, URLs     | Straight quotes "" '' | `aria-label="Close"` |

**Double vs single:**

- Use double quotes by default: "My Design"
- Use single quotes for quotes within quotes: "Rename 'Untitled' to something else"

**Avoid quotes for:**

- Emphasis — use bold instead
- Technical terms — just use the term
- Scare quotes — they feel sarcastic

## Numbers and Formatting

- Use numerals for counts: "3 files selected"
- Spell out in prose: "Choose one of the options"
- Use "and" not "&" in sentences
- Format dates naturally: "Jan 25, 2026"

## Aria Labels

Aria labels help screen reader users understand interactive elements.

### When to use

- Icon-only buttons (no visible text)
- Elements where visible text is insufficient
- Interactive images or graphics

### Writing principles

- **Describe the action, not the icon**: "Close" not "X button"
- **Be specific about context**: "Delete file" not just "Delete"
- **Use sentence case**: "Edit workspace settings"
- **Keep concise**: 2-5 words typically

### Examples

| Element       | ✅ Correct                 | ❌ Incorrect            |
| ------------- | -------------------------- | ----------------------- |
| Close button  | "Close" or "Close dialog"  | "X", "Close button"     |
| Delete icon   | "Delete file"              | "Trash", "Delete icon"  |
| Settings gear | "Settings"                 | "Gear", "Settings icon" |
| Search icon   | "Search"                   | "Magnifying glass"      |
| Menu toggle   | "Open menu" / "Close menu" | "Menu", "Hamburger"     |
| Copy button   | "Copy to clipboard"        | "Copy icon"             |
| External link | "Open in new tab"          | "External link"         |

### Patterns

**For toggles**, describe the action that will happen:

- Closed state: "Open menu"
- Open state: "Close menu"

**For items in lists**, include identifying context:

- "Delete 'My Design'" not just "Delete"
- "Edit 'Homepage' settings"

### Avoid

- Redundant words: ❌ "Button to close", "Click to delete"
- Icon descriptions: ❌ "Trash can icon", "Gear icon"
- Technical terms: ❌ "Toggle aria-expanded"
- Directional language: ❌ "Click the X in the corner"
