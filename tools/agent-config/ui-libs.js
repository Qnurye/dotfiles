import Editor from "@toast-ui/editor";
import "@toast-ui/editor/dist/toastui-editor.css";
import "@toast-ui/editor/dist/theme/toastui-editor-dark.css";
import "@toast-ui/editor/dist/i18n/zh-cn";
import { parseDocument } from "yaml";
import { parse, modify, applyEdits } from "jsonc-parser";

window.EditorTools = { Editor, parseDocument, parse, modify, applyEdits };
