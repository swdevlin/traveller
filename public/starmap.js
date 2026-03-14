// elm-watch hot {"version":"1.1.3","targetName":"main","webSocketPort":33487}
"use strict";
(() => {
  // node_modules/tiny-decoders/index.mjs
  function boolean(value) {
    if (typeof value !== "boolean") {
      throw new DecoderError({ tag: "boolean", got: value });
    }
    return value;
  }
  function number(value) {
    if (typeof value !== "number") {
      throw new DecoderError({ tag: "number", got: value });
    }
    return value;
  }
  function string(value) {
    if (typeof value !== "string") {
      throw new DecoderError({ tag: "string", got: value });
    }
    return value;
  }
  function stringUnion(mapping) {
    return function stringUnionDecoder(value) {
      const str = string(value);
      if (!Object.prototype.hasOwnProperty.call(mapping, str)) {
        throw new DecoderError({
          tag: "unknown stringUnion variant",
          knownVariants: Object.keys(mapping),
          got: str
        });
      }
      return str;
    };
  }
  function unknownArray(value) {
    if (!Array.isArray(value)) {
      throw new DecoderError({ tag: "array", got: value });
    }
    return value;
  }
  function unknownRecord(value) {
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
      throw new DecoderError({ tag: "object", got: value });
    }
    return value;
  }
  function array(decoder) {
    return function arrayDecoder(value) {
      const arr = unknownArray(value);
      const result = [];
      for (let index = 0; index < arr.length; index++) {
        try {
          result.push(decoder(arr[index]));
        } catch (error) {
          throw DecoderError.at(error, index);
        }
      }
      return result;
    };
  }
  function record(decoder) {
    return function recordDecoder(value) {
      const object = unknownRecord(value);
      const keys = Object.keys(object);
      const result = {};
      for (const key of keys) {
        if (key === "__proto__") {
          continue;
        }
        try {
          result[key] = decoder(object[key]);
        } catch (error) {
          throw DecoderError.at(error, key);
        }
      }
      return result;
    };
  }
  function fields(callback, { exact = "allow extra", allow = "object" } = {}) {
    return function fieldsDecoder(value) {
      const object = allow === "array" ? unknownArray(value) : unknownRecord(value);
      const knownFields = /* @__PURE__ */ Object.create(null);
      function field(key, decoder) {
        try {
          const result2 = decoder(object[key]);
          knownFields[key] = null;
          return result2;
        } catch (error) {
          throw DecoderError.at(error, key);
        }
      }
      const result = callback(field, object);
      if (exact !== "allow extra") {
        const unknownFields = Object.keys(object).filter((key) => !Object.prototype.hasOwnProperty.call(knownFields, key));
        if (unknownFields.length > 0) {
          throw new DecoderError({
            tag: "exact fields",
            knownFields: Object.keys(knownFields),
            got: unknownFields
          });
        }
      }
      return result;
    };
  }
  function fieldsAuto(mapping, { exact = "allow extra" } = {}) {
    return function fieldsAutoDecoder(value) {
      const object = unknownRecord(value);
      const keys = Object.keys(mapping);
      const result = {};
      for (const key of keys) {
        if (key === "__proto__") {
          continue;
        }
        const decoder = mapping[key];
        try {
          result[key] = decoder(object[key]);
        } catch (error) {
          throw DecoderError.at(error, key);
        }
      }
      if (exact !== "allow extra") {
        const unknownFields = Object.keys(object).filter((key) => !Object.prototype.hasOwnProperty.call(mapping, key));
        if (unknownFields.length > 0) {
          throw new DecoderError({
            tag: "exact fields",
            knownFields: keys,
            got: unknownFields
          });
        }
      }
      return result;
    };
  }
  function fieldsUnion(key, mapping) {
    return fields(function fieldsUnionFields(field, object) {
      const tag = field(key, string);
      if (Object.prototype.hasOwnProperty.call(mapping, tag)) {
        const decoder = mapping[tag];
        return decoder(object);
      }
      throw new DecoderError({
        tag: "unknown fieldsUnion tag",
        knownTags: Object.keys(mapping),
        got: tag,
        key
      });
    });
  }
  function multi(mapping) {
    return function multiDecoder(value) {
      if (value === void 0) {
        if (mapping.undefined !== void 0) {
          return mapping.undefined(value);
        }
      } else if (value === null) {
        if (mapping.null !== void 0) {
          return mapping.null(value);
        }
      } else if (typeof value === "boolean") {
        if (mapping.boolean !== void 0) {
          return mapping.boolean(value);
        }
      } else if (typeof value === "number") {
        if (mapping.number !== void 0) {
          return mapping.number(value);
        }
      } else if (typeof value === "string") {
        if (mapping.string !== void 0) {
          return mapping.string(value);
        }
      } else if (Array.isArray(value)) {
        if (mapping.array !== void 0) {
          return mapping.array(value);
        }
      } else {
        if (mapping.object !== void 0) {
          return mapping.object(value);
        }
      }
      throw new DecoderError({
        tag: "unknown multi type",
        knownTypes: Object.keys(mapping),
        got: value
      });
    };
  }
  function optional(decoder, defaultValue) {
    return function optionalDecoder(value) {
      if (value === void 0) {
        return defaultValue;
      }
      try {
        return decoder(value);
      } catch (error) {
        const newError = DecoderError.at(error);
        if (newError.path.length === 0) {
          newError.optional = true;
        }
        throw newError;
      }
    };
  }
  function chain(decoder, next) {
    return function chainDecoder(value) {
      return next(decoder(value));
    };
  }
  function formatDecoderErrorVariant(variant, options) {
    const formatGot = (value) => {
      const formatted = repr(value, options);
      return (options === null || options === void 0 ? void 0 : options.sensitive) === true ? `${formatted}
(Actual values are hidden in sensitive mode.)` : formatted;
    };
    const stringList = (strings) => strings.length === 0 ? "(none)" : strings.map((s) => JSON.stringify(s)).join(", ");
    const got = (message, value) => value === DecoderError.MISSING_VALUE ? message : `${message}
Got: ${formatGot(value)}`;
    switch (variant.tag) {
      case "boolean":
      case "number":
      case "string":
        return got(`Expected a ${variant.tag}`, variant.got);
      case "array":
      case "object":
        return got(`Expected an ${variant.tag}`, variant.got);
      case "unknown multi type":
        return `Expected one of these types: ${variant.knownTypes.length === 0 ? "never" : variant.knownTypes.join(", ")}
Got: ${formatGot(variant.got)}`;
      case "unknown fieldsUnion tag":
        return `Expected one of these tags: ${stringList(variant.knownTags)}
Got: ${formatGot(variant.got)}`;
      case "unknown stringUnion variant":
        return `Expected one of these variants: ${stringList(variant.knownVariants)}
Got: ${formatGot(variant.got)}`;
      case "exact fields":
        return `Expected only these fields: ${stringList(variant.knownFields)}
Found extra fields: ${formatGot(variant.got).replace(/^\[|\]$/g, "")}`;
      case "tuple size":
        return `Expected ${variant.expected} items
Got: ${variant.got}`;
      case "custom":
        return got(variant.message, variant.got);
    }
  }
  var DecoderError = class extends TypeError {
    constructor({ key, ...params }) {
      const variant = "tag" in params ? params : { tag: "custom", message: params.message, got: params.value };
      super(`${formatDecoderErrorVariant(
        variant,
        { sensitive: true }
      )}

For better error messages, see https://github.com/lydell/tiny-decoders#error-messages`);
      this.path = key === void 0 ? [] : [key];
      this.variant = variant;
      this.nullable = false;
      this.optional = false;
    }
    static at(error, key) {
      if (error instanceof DecoderError) {
        if (key !== void 0) {
          error.path.unshift(key);
        }
        return error;
      }
      return new DecoderError({
        tag: "custom",
        message: error instanceof Error ? error.message : String(error),
        got: DecoderError.MISSING_VALUE,
        key
      });
    }
    format(options) {
      const path = this.path.map((part) => `[${JSON.stringify(part)}]`).join("");
      const nullableString = this.nullable ? " (nullable)" : "";
      const optionalString = this.optional ? " (optional)" : "";
      const variant = formatDecoderErrorVariant(this.variant, options);
      return `At root${path}${nullableString}${optionalString}:
${variant}`;
    }
  };
  DecoderError.MISSING_VALUE = Symbol("DecoderError.MISSING_VALUE");
  function repr(value, { recurse = true, maxArrayChildren = 5, maxObjectChildren = 3, maxLength = 100, recurseMaxLength = 20, sensitive = false } = {}) {
    const type = typeof value;
    const toStringType = Object.prototype.toString.call(value).replace(/^\[object\s+(.+)\]$/, "$1");
    try {
      if (value == null || type === "number" || type === "boolean" || type === "symbol" || toStringType === "RegExp") {
        return sensitive ? toStringType.toLowerCase() : truncate(String(value), maxLength);
      }
      if (type === "string") {
        return sensitive ? type : truncate(JSON.stringify(value), maxLength);
      }
      if (typeof value === "function") {
        return `function ${truncate(JSON.stringify(value.name), maxLength)}`;
      }
      if (Array.isArray(value)) {
        const arr = value;
        if (!recurse && arr.length > 0) {
          return `${toStringType}(${arr.length})`;
        }
        const lastIndex = arr.length - 1;
        const items = [];
        const end = Math.min(maxArrayChildren - 1, lastIndex);
        for (let index = 0; index <= end; index++) {
          const item = index in arr ? repr(arr[index], {
            recurse: false,
            maxLength: recurseMaxLength,
            sensitive
          }) : "<empty>";
          items.push(item);
        }
        if (end < lastIndex) {
          items.push(`(${lastIndex - end} more)`);
        }
        return `[${items.join(", ")}]`;
      }
      if (toStringType === "Object") {
        const object = value;
        const keys = Object.keys(object);
        const { name } = object.constructor;
        if (!recurse && keys.length > 0) {
          return `${name}(${keys.length})`;
        }
        const numHidden = Math.max(0, keys.length - maxObjectChildren);
        const items = keys.slice(0, maxObjectChildren).map((key2) => `${truncate(JSON.stringify(key2), recurseMaxLength)}: ${repr(object[key2], {
          recurse: false,
          maxLength: recurseMaxLength,
          sensitive
        })}`).concat(numHidden > 0 ? `(${numHidden} more)` : []);
        const prefix = name === "Object" ? "" : `${name} `;
        return `${prefix}{${items.join(", ")}}`;
      }
      return toStringType;
    } catch (_error) {
      return toStringType;
    }
  }
  function truncate(str, maxLength) {
    const half = Math.floor(maxLength / 2);
    return str.length <= maxLength ? str : `${str.slice(0, half)}\u2026${str.slice(-half)}`;
  }

  // src/Helpers.ts
  function join(array2, separator) {
    return array2.join(separator);
  }
  function pad(number2) {
    return number2.toString().padStart(2, "0");
  }
  function formatDate(date) {
    return join(
      [pad(date.getFullYear()), pad(date.getMonth() + 1), pad(date.getDate())],
      "-"
    );
  }
  function formatTime(date) {
    return join(
      [pad(date.getHours()), pad(date.getMinutes()), pad(date.getSeconds())],
      ":"
    );
  }

  // src/TeaProgram.ts
  async function runTeaProgram(options) {
    return new Promise((resolve, reject) => {
      const [initialModel, initialCmds] = options.init;
      let model = initialModel;
      const msgQueue = [];
      let killed = false;
      const dispatch = (dispatchedMsg) => {
        if (killed) {
          return;
        }
        const alreadyRunning = msgQueue.length > 0;
        msgQueue.push(dispatchedMsg);
        if (alreadyRunning) {
          return;
        }
        for (const msg of msgQueue) {
          const [newModel, cmds] = options.update(msg, model);
          model = newModel;
          runCmds(cmds);
        }
        msgQueue.length = 0;
      };
      const runCmds = (cmds) => {
        for (const cmd of cmds) {
          options.runCmd(
            cmd,
            mutable,
            dispatch,
            (result) => {
              cmds.length = 0;
              killed = true;
              resolve(result);
            },
            (error) => {
              cmds.length = 0;
              killed = true;
              reject(error);
            }
          );
          if (killed) {
            break;
          }
        }
      };
      const mutable = options.initMutable(
        dispatch,
        (result) => {
          killed = true;
          resolve(result);
        },
        (error) => {
          killed = true;
          reject(error);
        }
      );
      runCmds(initialCmds);
    });
  }

  // src/Types.ts
  var AbsolutePath = fieldsAuto({
    tag: () => "AbsolutePath",
    absolutePath: string
  });
  var CompilationMode = stringUnion({
    debug: null,
    standard: null,
    optimize: null
  });
  var BrowserUiPosition = stringUnion({
    TopLeft: null,
    TopRight: null,
    BottomLeft: null,
    BottomRight: null
  });

  // client/WebSocketMessages.ts
  var FocusedTabAcknowledged = fieldsAuto({
    tag: () => "FocusedTabAcknowledged"
  });
  var OpenEditorError = fieldsUnion("tag", {
    EnvNotSet: fieldsAuto({
      tag: () => "EnvNotSet"
    }),
    CommandFailed: fieldsAuto({
      tag: () => "CommandFailed",
      message: string
    })
  });
  var OpenEditorFailed = fieldsAuto({
    tag: () => "OpenEditorFailed",
    error: OpenEditorError
  });
  var ErrorLocation = fieldsUnion("tag", {
    FileOnly: fieldsAuto({
      tag: () => "FileOnly",
      file: AbsolutePath
    }),
    FileWithLineAndColumn: fieldsAuto({
      tag: () => "FileWithLineAndColumn",
      file: AbsolutePath,
      line: number,
      column: number
    }),
    Target: fieldsAuto({
      tag: () => "Target",
      targetName: string
    })
  });
  var CompileError = fieldsAuto({
    title: string,
    location: optional(ErrorLocation),
    htmlContent: string
  });
  var StatusChanged = fieldsAuto({
    tag: () => "StatusChanged",
    status: fieldsUnion("tag", {
      AlreadyUpToDate: fieldsAuto({
        tag: () => "AlreadyUpToDate",
        compilationMode: CompilationMode,
        browserUiPosition: BrowserUiPosition
      }),
      Busy: fieldsAuto({
        tag: () => "Busy",
        compilationMode: CompilationMode,
        browserUiPosition: BrowserUiPosition
      }),
      CompileError: fieldsAuto({
        tag: () => "CompileError",
        compilationMode: CompilationMode,
        browserUiPosition: BrowserUiPosition,
        openErrorOverlay: boolean,
        errors: array(CompileError),
        foregroundColor: string,
        backgroundColor: string
      }),
      ElmJsonError: fieldsAuto({
        tag: () => "ElmJsonError",
        error: string
      }),
      ClientError: fieldsAuto({
        tag: () => "ClientError",
        message: string
      })
    })
  });
  var SuccessfullyCompiled = fieldsAuto({
    tag: () => "SuccessfullyCompiled",
    code: string,
    elmCompiledTimestamp: number,
    compilationMode: CompilationMode,
    browserUiPosition: BrowserUiPosition
  });
  var SuccessfullyCompiledButRecordFieldsChanged = fieldsAuto({
    tag: () => "SuccessfullyCompiledButRecordFieldsChanged"
  });
  var WebSocketToClientMessage = fieldsUnion("tag", {
    FocusedTabAcknowledged,
    OpenEditorFailed,
    StatusChanged,
    SuccessfullyCompiled,
    SuccessfullyCompiledButRecordFieldsChanged
  });
  var WebSocketToServerMessage = fieldsUnion("tag", {
    ChangedCompilationMode: fieldsAuto({
      tag: () => "ChangedCompilationMode",
      compilationMode: CompilationMode
    }),
    ChangedBrowserUiPosition: fieldsAuto({
      tag: () => "ChangedBrowserUiPosition",
      browserUiPosition: BrowserUiPosition
    }),
    ChangedOpenErrorOverlay: fieldsAuto({
      tag: () => "ChangedOpenErrorOverlay",
      openErrorOverlay: boolean
    }),
    FocusedTab: fieldsAuto({
      tag: () => "FocusedTab"
    }),
    PressedOpenEditor: fieldsAuto({
      tag: () => "PressedOpenEditor",
      file: AbsolutePath,
      line: number,
      column: number
    })
  });
  function decodeWebSocketToClientMessage(message) {
    if (message.startsWith("//")) {
      const newlineIndexRaw = message.indexOf("\n");
      const newlineIndex = newlineIndexRaw === -1 ? message.length : newlineIndexRaw;
      const jsonString = message.slice(2, newlineIndex);
      const parsed = SuccessfullyCompiled(JSON.parse(jsonString));
      return { ...parsed, code: message };
    } else {
      return WebSocketToClientMessage(JSON.parse(message));
    }
  }

  // client/client.ts
  var window = globalThis;
  var IS_WEB_WORKER = window.window === void 0;
  var { __ELM_WATCH } = window;
  if (typeof __ELM_WATCH !== "object" || __ELM_WATCH === null) {
    __ELM_WATCH = {};
    Object.defineProperty(window, "__ELM_WATCH", { value: __ELM_WATCH });
  }
  __ELM_WATCH.MOCKED_TIMINGS ?? (__ELM_WATCH.MOCKED_TIMINGS = false);
  __ELM_WATCH.WEBSOCKET_TIMEOUT ?? (__ELM_WATCH.WEBSOCKET_TIMEOUT = 1e3);
  __ELM_WATCH.ON_INIT ?? (__ELM_WATCH.ON_INIT = () => {
  });
  __ELM_WATCH.ON_RENDER ?? (__ELM_WATCH.ON_RENDER = () => {
  });
  __ELM_WATCH.ON_REACHED_IDLE_STATE ?? (__ELM_WATCH.ON_REACHED_IDLE_STATE = () => {
  });
  __ELM_WATCH.RELOAD_STATUSES ?? (__ELM_WATCH.RELOAD_STATUSES = {});
  var RELOAD_MESSAGE_KEY = "__elmWatchReloadMessage";
  var RELOAD_TARGET_NAME_KEY_PREFIX = "__elmWatchReloadTarget__";
  __ELM_WATCH.RELOAD_PAGE ?? (__ELM_WATCH.RELOAD_PAGE = (message) => {
    if (message !== void 0) {
      try {
        window.sessionStorage.setItem(RELOAD_MESSAGE_KEY, message);
      } catch {
      }
    }
    if (IS_WEB_WORKER) {
      if (message !== void 0) {
        console.info(message);
      }
      console.error(
        message === void 0 ? "elm-watch: You need to reload the page! I seem to be running in a Web Worker, so I can\u2019t do it for you." : `elm-watch: You need to reload the page! I seem to be running in a Web Worker, so I couldn\u2019t actually reload the page (see above).`
      );
    } else {
      window.location.reload();
    }
  });
  __ELM_WATCH.KILL_MATCHING ?? (__ELM_WATCH.KILL_MATCHING = () => Promise.resolve());
  __ELM_WATCH.DISCONNECT ?? (__ELM_WATCH.DISCONNECT = () => {
  });
  __ELM_WATCH.LOG_DEBUG ?? (__ELM_WATCH.LOG_DEBUG = console.debug);
  var VERSION = "1.1.3";
  var TARGET_NAME = "main";
  var INITIAL_ELM_COMPILED_TIMESTAMP = Number(
    "1773504618975"
  );
  var ORIGINAL_COMPILATION_MODE = "standard";
  var ORIGINAL_BROWSER_UI_POSITION = "BottomLeft";
  var WEBSOCKET_PORT = "33487";
  var CONTAINER_ID = "elm-watch";
  var DEBUG = String("false") === "true";
  var BROWSER_UI_MOVED_EVENT = "BROWSER_UI_MOVED_EVENT";
  var CLOSE_ALL_ERROR_OVERLAYS_EVENT = "CLOSE_ALL_ERROR_OVERLAYS_EVENT";
  var JUST_CHANGED_BROWSER_UI_POSITION_TIMEOUT = 2e3;
  var SEND_KEY_DO_NOT_USE_ALL_THE_TIME = Symbol(
    "This value is supposed to only be obtained via `Status`."
  );
  function logDebug(...args) {
    if (DEBUG) {
      __ELM_WATCH.LOG_DEBUG(...args);
    }
  }
  function parseBrowseUiPositionWithFallback(value) {
    try {
      return BrowserUiPosition(value);
    } catch {
      return ORIGINAL_BROWSER_UI_POSITION;
    }
  }
  function run() {
    let elmCompiledTimestampBeforeReload = void 0;
    try {
      const message = window.sessionStorage.getItem(RELOAD_MESSAGE_KEY);
      if (message !== null) {
        console.info(message);
        window.sessionStorage.removeItem(RELOAD_MESSAGE_KEY);
      }
      const key = RELOAD_TARGET_NAME_KEY_PREFIX + TARGET_NAME;
      const previous = window.sessionStorage.getItem(key);
      if (previous !== null) {
        const number2 = Number(previous);
        if (Number.isFinite(number2)) {
          elmCompiledTimestampBeforeReload = number2;
        }
        window.sessionStorage.removeItem(key);
      }
    } catch {
    }
    const elements = IS_WEB_WORKER ? void 0 : getOrCreateTargetRoot();
    const browserUiPosition = elements === void 0 ? ORIGINAL_BROWSER_UI_POSITION : parseBrowseUiPositionWithFallback(elements.container.dataset.position);
    const getNow = () => new Date();
    runTeaProgram({
      initMutable: initMutable(getNow, elements),
      init: init(getNow(), browserUiPosition, elmCompiledTimestampBeforeReload),
      update: (msg, model) => {
        const [updatedModel, cmds] = update(msg, model);
        const modelChanged = updatedModel !== model;
        const reloadTrouble = model.status.tag !== updatedModel.status.tag && updatedModel.status.tag === "WaitingForReload" && updatedModel.elmCompiledTimestamp === updatedModel.elmCompiledTimestampBeforeReload;
        const newModel = modelChanged ? {
          ...updatedModel,
          previousStatusTag: model.status.tag,
          uiExpanded: reloadTrouble ? true : updatedModel.uiExpanded
        } : model;
        const oldErrorOverlay = getErrorOverlay(model.status);
        const newErrorOverlay = getErrorOverlay(newModel.status);
        const allCmds = modelChanged ? [
          ...cmds,
          {
            tag: "UpdateGlobalStatus",
            reloadStatus: statusToReloadStatus(newModel),
            elmCompiledTimestamp: newModel.elmCompiledTimestamp
          },
          newModel.status.tag === newModel.previousStatusTag && oldErrorOverlay?.openErrorOverlay === newErrorOverlay?.openErrorOverlay ? { tag: "NoCmd" } : {
            tag: "UpdateErrorOverlay",
            errors: newErrorOverlay === void 0 || !newErrorOverlay.openErrorOverlay ? /* @__PURE__ */ new Map() : newErrorOverlay.errors,
            sendKey: statusToSpecialCaseSendKey(newModel.status)
          },
          {
            tag: "Render",
            model: newModel,
            manageFocus: msg.tag === "UiMsg"
          },
          model.browserUiPosition === newModel.browserUiPosition ? { tag: "NoCmd" } : {
            tag: "SetBrowserUiPosition",
            browserUiPosition: newModel.browserUiPosition
          },
          reloadTrouble ? { tag: "TriggerReachedIdleState", reason: "ReloadTrouble" } : { tag: "NoCmd" }
        ] : cmds;
        logDebug(`${msg.tag} (${TARGET_NAME})`, msg, newModel, allCmds);
        return [newModel, allCmds];
      },
      runCmd: runCmd(getNow, elements)
    }).catch((error) => {
      console.error("elm-watch: Unexpectedly exited with error:", error);
    });
  }
  function getErrorOverlay(status) {
    return "errorOverlay" in status ? status.errorOverlay : void 0;
  }
  function statusToReloadStatus(model) {
    switch (model.status.tag) {
      case "Busy":
      case "Connecting":
        return { tag: "MightWantToReload" };
      case "CompileError":
      case "ElmJsonError":
      case "EvalError":
      case "Idle":
      case "SleepingBeforeReconnect":
      case "UnexpectedError":
        return { tag: "NoReloadWanted" };
      case "WaitingForReload":
        return model.elmCompiledTimestamp === model.elmCompiledTimestampBeforeReload ? { tag: "NoReloadWanted" } : { tag: "ReloadRequested", reasons: model.status.reasons };
    }
  }
  function statusToStatusType(statusTag) {
    switch (statusTag) {
      case "Idle":
        return "Success";
      case "Busy":
      case "Connecting":
      case "SleepingBeforeReconnect":
      case "WaitingForReload":
        return "Waiting";
      case "CompileError":
      case "ElmJsonError":
      case "EvalError":
      case "UnexpectedError":
        return "Error";
    }
  }
  function statusToSpecialCaseSendKey(status) {
    switch (status.tag) {
      case "CompileError":
      case "Idle":
        return status.sendKey;
      case "Busy":
        return SEND_KEY_DO_NOT_USE_ALL_THE_TIME;
      case "Connecting":
      case "SleepingBeforeReconnect":
      case "WaitingForReload":
      case "ElmJsonError":
      case "EvalError":
      case "UnexpectedError":
        return void 0;
    }
  }
  function getOrCreateContainer() {
    const existing = document.getElementById(CONTAINER_ID);
    if (existing !== null) {
      return existing;
    }
    const container = h(HTMLDivElement, { id: CONTAINER_ID });
    container.style.all = "unset";
    container.style.position = "fixed";
    container.style.zIndex = "2147483647";
    const shadowRoot = container.attachShadow({ mode: "open" });
    shadowRoot.append(h(HTMLStyleElement, {}, CSS));
    document.documentElement.append(container);
    return container;
  }
  function getOrCreateTargetRoot() {
    const container = getOrCreateContainer();
    const { shadowRoot } = container;
    if (shadowRoot === null) {
      throw new Error(
        `elm-watch: Cannot set up hot reload, because an element with ID ${CONTAINER_ID} exists, but \`.shadowRoot\` is null!`
      );
    }
    let overlay = shadowRoot.querySelector(`.${CLASS.overlay}`);
    if (overlay === null) {
      overlay = h(HTMLDivElement, {
        className: CLASS.overlay,
        attrs: { "data-test-id": "Overlay" }
      });
      shadowRoot.append(overlay);
    }
    let overlayCloseButton = shadowRoot.querySelector(
      `.${CLASS.overlayCloseButton}`
    );
    if (overlayCloseButton === null) {
      const closeAllErrorOverlays = () => {
        shadowRoot.dispatchEvent(new CustomEvent(CLOSE_ALL_ERROR_OVERLAYS_EVENT));
      };
      overlayCloseButton = h(HTMLButtonElement, {
        className: CLASS.overlayCloseButton,
        attrs: {
          "aria-label": "Close error overlay",
          "data-test-id": "OverlayCloseButton"
        },
        onclick: closeAllErrorOverlays
      });
      shadowRoot.append(overlayCloseButton);
      const overlayNonNull = overlay;
      window.addEventListener(
        "keydown",
        (event) => {
          if (overlayNonNull.hasChildNodes() && event.key === "Escape") {
            event.preventDefault();
            event.stopImmediatePropagation();
            closeAllErrorOverlays();
          }
        },
        true
      );
    }
    let root = shadowRoot.querySelector(`.${CLASS.root}`);
    if (root === null) {
      root = h(HTMLDivElement, { className: CLASS.root });
      shadowRoot.append(root);
    }
    const targetRoot = createTargetRoot(TARGET_NAME);
    root.append(targetRoot);
    const elements = {
      container,
      shadowRoot,
      overlay,
      overlayCloseButton,
      root,
      targetRoot
    };
    setBrowserUiPosition(ORIGINAL_BROWSER_UI_POSITION, elements);
    return elements;
  }
  function createTargetRoot(targetName) {
    return h(HTMLDivElement, {
      className: CLASS.targetRoot,
      attrs: { "data-target": targetName }
    });
  }
  function browserUiPositionToCss(browserUiPosition) {
    switch (browserUiPosition) {
      case "TopLeft":
        return { top: "-1px", bottom: "auto", left: "-1px", right: "auto" };
      case "TopRight":
        return { top: "-1px", bottom: "auto", left: "auto", right: "-1px" };
      case "BottomLeft":
        return { top: "auto", bottom: "-1px", left: "-1px", right: "auto" };
      case "BottomRight":
        return { top: "auto", bottom: "-1px", left: "auto", right: "-1px" };
    }
  }
  function browserUiPositionToCssForChooser(browserUiPosition) {
    switch (browserUiPosition) {
      case "TopLeft":
        return { top: "auto", bottom: "0", left: "auto", right: "0" };
      case "TopRight":
        return { top: "auto", bottom: "0", left: "0", right: "auto" };
      case "BottomLeft":
        return { top: "0", bottom: "auto", left: "auto", right: "0" };
      case "BottomRight":
        return { top: "0", bottom: "auto", left: "0", right: "auto" };
    }
  }
  function setBrowserUiPosition(browserUiPosition, elements) {
    const isFirstTargetRoot = elements.targetRoot.previousElementSibling === null;
    if (!isFirstTargetRoot) {
      return;
    }
    elements.container.dataset.position = browserUiPosition;
    for (const [key, value] of Object.entries(
      browserUiPositionToCss(browserUiPosition)
    )) {
      elements.container.style.setProperty(key, value);
    }
    const isInBottomHalf = browserUiPosition === "BottomLeft" || browserUiPosition === "BottomRight";
    elements.root.classList.toggle(CLASS.rootBottomHalf, isInBottomHalf);
    elements.shadowRoot.dispatchEvent(
      new CustomEvent(BROWSER_UI_MOVED_EVENT, { detail: browserUiPosition })
    );
  }
  var initMutable = (getNow, elements) => (dispatch, resolvePromise) => {
    let removeListeners = [];
    const mutable = {
      removeListeners: () => {
        for (const removeListener of removeListeners) {
          removeListener();
        }
      },
      webSocket: initWebSocket(
        getNow,
        INITIAL_ELM_COMPILED_TIMESTAMP,
        dispatch
      ),
      webSocketTimeoutId: void 0
    };
    mutable.webSocket.addEventListener(
      "open",
      () => {
        removeListeners = [
          addEventListener(window, "focus", (event) => {
            if (event instanceof CustomEvent && event.detail !== TARGET_NAME) {
              return;
            }
            dispatch({ tag: "FocusedTab" });
          }),
          addEventListener(window, "visibilitychange", () => {
            if (document.visibilityState === "visible") {
              dispatch({
                tag: "PageVisibilityChangedToVisible",
                date: getNow()
              });
            }
          }),
          ...elements === void 0 ? [] : [
            addEventListener(
              elements.shadowRoot,
              BROWSER_UI_MOVED_EVENT,
              (event) => {
                dispatch({
                  tag: "BrowserUiMoved",
                  browserUiPosition: fields(
                    (field) => field("detail", parseBrowseUiPositionWithFallback)
                  )(event)
                });
              }
            ),
            addEventListener(
              elements.shadowRoot,
              CLOSE_ALL_ERROR_OVERLAYS_EVENT,
              () => {
                dispatch({
                  tag: "UiMsg",
                  date: getNow(),
                  msg: {
                    tag: "ChangedOpenErrorOverlay",
                    openErrorOverlay: false
                  }
                });
              }
            )
          ]
        ];
      },
      { once: true }
    );
    __ELM_WATCH.RELOAD_STATUSES[TARGET_NAME] = {
      tag: "MightWantToReload"
    };
    const originalOnInit = __ELM_WATCH.ON_INIT;
    __ELM_WATCH.ON_INIT = () => {
      dispatch({ tag: "AppInit" });
      originalOnInit();
    };
    const originalKillMatching = __ELM_WATCH.KILL_MATCHING;
    __ELM_WATCH.KILL_MATCHING = (targetName) => new Promise((resolve, reject) => {
      if (targetName.test(TARGET_NAME) && mutable.webSocket.readyState !== WebSocket.CLOSED) {
        mutable.webSocket.addEventListener("close", () => {
          originalKillMatching(targetName).then(resolve).catch(reject);
        });
        mutable.removeListeners();
        mutable.webSocket.close();
        if (mutable.webSocketTimeoutId !== void 0) {
          clearTimeout(mutable.webSocketTimeoutId);
          mutable.webSocketTimeoutId = void 0;
        }
        elements?.targetRoot.remove();
        resolvePromise(void 0);
      } else {
        originalKillMatching(targetName).then(resolve).catch(reject);
      }
    });
    const originalDisconnect = __ELM_WATCH.DISCONNECT;
    __ELM_WATCH.DISCONNECT = (targetName) => {
      if (targetName.test(TARGET_NAME) && mutable.webSocket.readyState !== WebSocket.CLOSED) {
        mutable.webSocket.close();
      } else {
        originalDisconnect(targetName);
      }
    };
    return mutable;
  };
  function addEventListener(target, eventName, listener) {
    target.addEventListener(eventName, listener);
    return () => {
      target.removeEventListener(eventName, listener);
    };
  }
  function initWebSocket(getNow, elmCompiledTimestamp, dispatch) {
    const hostname = window.location.hostname === "" ? "localhost" : window.location.hostname;
    const protocol = window.location.protocol === "https:" ? "wss" : "ws";
    const url = new URL(`${protocol}://${hostname}:${WEBSOCKET_PORT}/elm-watch`);
    url.searchParams.set("elmWatchVersion", VERSION);
    url.searchParams.set("targetName", TARGET_NAME);
    url.searchParams.set("elmCompiledTimestamp", elmCompiledTimestamp.toString());
    const webSocket = new WebSocket(url);
    webSocket.addEventListener("open", () => {
      dispatch({ tag: "WebSocketConnected", date: getNow() });
    });
    webSocket.addEventListener("close", () => {
      dispatch({
        tag: "WebSocketClosed",
        date: getNow()
      });
    });
    webSocket.addEventListener("message", (event) => {
      dispatch({
        tag: "WebSocketMessageReceived",
        date: getNow(),
        data: event.data
      });
    });
    return webSocket;
  }
  var init = (date, browserUiPosition, elmCompiledTimestampBeforeReload) => {
    const model = {
      status: { tag: "Connecting", date, attemptNumber: 1 },
      previousStatusTag: "Idle",
      compilationMode: ORIGINAL_COMPILATION_MODE,
      browserUiPosition,
      lastBrowserUiPositionChangeDate: void 0,
      elmCompiledTimestamp: INITIAL_ELM_COMPILED_TIMESTAMP,
      elmCompiledTimestampBeforeReload,
      uiExpanded: false
    };
    return [model, [{ tag: "Render", model, manageFocus: false }]];
  };
  function update(msg, model) {
    switch (msg.tag) {
      case "AppInit":
        return [{ ...model }, []];
      case "BrowserUiMoved":
        return [{ ...model, browserUiPosition: msg.browserUiPosition }, []];
      case "EvalErrored":
        return [
          {
            ...model,
            status: { tag: "EvalError", date: msg.date },
            uiExpanded: true
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "EvalErrored"
            }
          ]
        ];
      case "EvalNeedsReload":
        return [
          {
            ...model,
            status: {
              tag: "WaitingForReload",
              date: msg.date,
              reasons: msg.reasons
            }
          },
          []
        ];
      case "EvalSucceeded":
        return [
          {
            ...model,
            status: {
              tag: "Idle",
              date: msg.date,
              sendKey: SEND_KEY_DO_NOT_USE_ALL_THE_TIME
            }
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "EvalSucceeded"
            }
          ]
        ];
      case "FocusedTab":
        return [
          statusToStatusType(model.status.tag) === "Error" ? { ...model } : model,
          [
            {
              tag: "SendMessage",
              message: { tag: "FocusedTab" },
              sendKey: SEND_KEY_DO_NOT_USE_ALL_THE_TIME
            },
            {
              tag: "WebSocketTimeoutBegin"
            }
          ]
        ];
      case "PageVisibilityChangedToVisible":
        return reconnect(model, msg.date, { force: true });
      case "SleepBeforeReconnectDone":
        return reconnect(model, msg.date, { force: false });
      case "UiMsg":
        return onUiMsg(msg.date, msg.msg, model);
      case "WebSocketClosed": {
        const attemptNumber = "attemptNumber" in model.status ? model.status.attemptNumber + 1 : 1;
        return [
          {
            ...model,
            status: {
              tag: "SleepingBeforeReconnect",
              date: msg.date,
              attemptNumber
            }
          },
          [{ tag: "SleepBeforeReconnect", attemptNumber }]
        ];
      }
      case "WebSocketConnected":
        return [
          {
            ...model,
            status: { tag: "Busy", date: msg.date, errorOverlay: void 0 }
          },
          []
        ];
      case "WebSocketMessageReceived": {
        const result = parseWebSocketMessageData(msg.data);
        switch (result.tag) {
          case "Success":
            return onWebSocketToClientMessage(msg.date, result.message, model);
          case "Error":
            return [
              {
                ...model,
                status: {
                  tag: "UnexpectedError",
                  date: msg.date,
                  message: result.message
                },
                uiExpanded: true
              },
              []
            ];
        }
      }
    }
  }
  function onUiMsg(date, msg, model) {
    switch (msg.tag) {
      case "ChangedBrowserUiPosition":
        return [
          {
            ...model,
            browserUiPosition: msg.browserUiPosition,
            lastBrowserUiPositionChangeDate: date
          },
          [
            {
              tag: "SendMessage",
              message: {
                tag: "ChangedBrowserUiPosition",
                browserUiPosition: msg.browserUiPosition
              },
              sendKey: msg.sendKey
            }
          ]
        ];
      case "ChangedCompilationMode":
        return [
          {
            ...model,
            status: {
              tag: "Busy",
              date,
              errorOverlay: getErrorOverlay(model.status)
            },
            compilationMode: msg.compilationMode
          },
          [
            {
              tag: "SendMessage",
              message: {
                tag: "ChangedCompilationMode",
                compilationMode: msg.compilationMode
              },
              sendKey: msg.sendKey
            }
          ]
        ];
      case "ChangedOpenErrorOverlay":
        return "errorOverlay" in model.status && model.status.errorOverlay !== void 0 ? [
          {
            ...model,
            status: {
              ...model.status,
              errorOverlay: {
                ...model.status.errorOverlay,
                openErrorOverlay: msg.openErrorOverlay
              }
            },
            uiExpanded: false
          },
          [
            {
              tag: "SendMessage",
              message: {
                tag: "ChangedOpenErrorOverlay",
                openErrorOverlay: msg.openErrorOverlay
              },
              sendKey: model.status.tag === "Busy" ? SEND_KEY_DO_NOT_USE_ALL_THE_TIME : model.status.sendKey
            }
          ]
        ] : [model, []];
      case "PressedChevron":
        return [{ ...model, uiExpanded: !model.uiExpanded }, []];
      case "PressedOpenEditor":
        return [
          model,
          [
            {
              tag: "SendMessage",
              message: {
                tag: "PressedOpenEditor",
                file: msg.file,
                line: msg.line,
                column: msg.column
              },
              sendKey: msg.sendKey
            }
          ]
        ];
      case "PressedReconnectNow":
        return reconnect(model, date, { force: true });
    }
  }
  function onWebSocketToClientMessage(date, msg, model) {
    switch (msg.tag) {
      case "FocusedTabAcknowledged":
        return [model, [{ tag: "WebSocketTimeoutClear" }]];
      case "OpenEditorFailed":
        return [
          model.status.tag === "CompileError" ? {
            ...model,
            status: { ...model.status, openEditorError: msg.error },
            uiExpanded: true
          } : model,
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "OpenEditorFailed"
            }
          ]
        ];
      case "StatusChanged":
        return statusChanged(date, msg, model);
      case "SuccessfullyCompiled": {
        const justChangedBrowserUiPosition = model.lastBrowserUiPositionChangeDate !== void 0 && date.getTime() - model.lastBrowserUiPositionChangeDate.getTime() < JUST_CHANGED_BROWSER_UI_POSITION_TIMEOUT;
        return msg.compilationMode !== ORIGINAL_COMPILATION_MODE ? [
          {
            ...model,
            status: {
              tag: "WaitingForReload",
              date,
              reasons: ORIGINAL_COMPILATION_MODE === "proxy" ? [] : [
                `compilation mode changed from ${ORIGINAL_COMPILATION_MODE} to ${msg.compilationMode}.`
              ]
            },
            compilationMode: msg.compilationMode
          },
          []
        ] : [
          {
            ...model,
            compilationMode: msg.compilationMode,
            elmCompiledTimestamp: msg.elmCompiledTimestamp,
            browserUiPosition: msg.browserUiPosition,
            lastBrowserUiPositionChangeDate: void 0
          },
          [
            { tag: "Eval", code: msg.code },
            justChangedBrowserUiPosition ? {
              tag: "SetBrowserUiPosition",
              browserUiPosition: msg.browserUiPosition
            } : { tag: "NoCmd" }
          ]
        ];
      }
      case "SuccessfullyCompiledButRecordFieldsChanged":
        return [
          {
            ...model,
            status: {
              tag: "WaitingForReload",
              date,
              reasons: [
                `record field mangling in optimize mode was different than last time.`
              ]
            }
          },
          []
        ];
    }
  }
  function statusChanged(date, { status }, model) {
    switch (status.tag) {
      case "AlreadyUpToDate":
        return [
          {
            ...model,
            status: {
              tag: "Idle",
              date,
              sendKey: SEND_KEY_DO_NOT_USE_ALL_THE_TIME
            },
            compilationMode: status.compilationMode,
            browserUiPosition: status.browserUiPosition
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "AlreadyUpToDate"
            }
          ]
        ];
      case "Busy":
        return [
          {
            ...model,
            status: {
              tag: "Busy",
              date,
              errorOverlay: getErrorOverlay(model.status)
            },
            compilationMode: status.compilationMode,
            browserUiPosition: status.browserUiPosition
          },
          []
        ];
      case "ClientError":
        return [
          {
            ...model,
            status: { tag: "UnexpectedError", date, message: status.message },
            uiExpanded: true
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "ClientError"
            }
          ]
        ];
      case "CompileError":
        return [
          {
            ...model,
            status: {
              tag: "CompileError",
              date,
              sendKey: SEND_KEY_DO_NOT_USE_ALL_THE_TIME,
              errorOverlay: {
                errors: new Map(
                  status.errors.map((error) => {
                    const overlayError = {
                      title: error.title,
                      location: error.location,
                      htmlContent: error.htmlContent,
                      foregroundColor: status.foregroundColor,
                      backgroundColor: status.backgroundColor
                    };
                    const id = JSON.stringify(overlayError);
                    return [id, overlayError];
                  })
                ),
                openErrorOverlay: status.openErrorOverlay
              },
              openEditorError: void 0
            },
            compilationMode: status.compilationMode,
            browserUiPosition: status.browserUiPosition
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "CompileError"
            }
          ]
        ];
      case "ElmJsonError":
        return [
          {
            ...model,
            status: { tag: "ElmJsonError", date, error: status.error }
          },
          [
            {
              tag: "TriggerReachedIdleState",
              reason: "ElmJsonError"
            }
          ]
        ];
    }
  }
  function reconnect(model, date, { force }) {
    return model.status.tag === "SleepingBeforeReconnect" && (date.getTime() - model.status.date.getTime() >= retryWaitMs(model.status.attemptNumber) || force) ? [
      {
        ...model,
        status: {
          tag: "Connecting",
          date,
          attemptNumber: model.status.attemptNumber
        }
      },
      [
        {
          tag: "Reconnect",
          elmCompiledTimestamp: model.elmCompiledTimestamp
        }
      ]
    ] : [model, []];
  }
  function retryWaitMs(attemptNumber) {
    return Math.min(1e3 + 10 * attemptNumber ** 2, 1e3 * 60);
  }
  function printRetryWaitMs(attemptNumber) {
    return `${retryWaitMs(attemptNumber) / 1e3} seconds`;
  }
  var runCmd = (getNow, elements) => (cmd, mutable, dispatch, _resolvePromise, rejectPromise) => {
    switch (cmd.tag) {
      case "Eval": {
        try {
          const f = new Function(cmd.code);
          f();
          dispatch({ tag: "EvalSucceeded", date: getNow() });
        } catch (unknownError) {
          if (unknownError instanceof Error && unknownError.message.startsWith("ELM_WATCH_RELOAD_NEEDED")) {
            dispatch({
              tag: "EvalNeedsReload",
              date: getNow(),
              reasons: unknownError.message.split("\n\n---\n\n").slice(1)
            });
          } else {
            void Promise.reject(unknownError);
            dispatch({ tag: "EvalErrored", date: getNow() });
          }
        }
        return;
      }
      case "NoCmd":
        return;
      case "Reconnect":
        mutable.webSocket = initWebSocket(
          getNow,
          cmd.elmCompiledTimestamp,
          dispatch
        );
        return;
      case "Render": {
        const { model } = cmd;
        const info = {
          version: VERSION,
          webSocketUrl: new URL(mutable.webSocket.url),
          targetName: TARGET_NAME,
          originalCompilationMode: ORIGINAL_COMPILATION_MODE,
          initializedElmAppsStatus: checkInitializedElmAppsStatus(),
          errorOverlayVisible: elements !== void 0 && !elements.overlay.hidden
        };
        if (elements === void 0) {
          if (model.status.tag !== model.previousStatusTag) {
            const isError = statusToStatusType(model.status.tag) === "Error";
            const consoleMethod = isError ? console.error : console.info;
            consoleMethod(renderWebWorker(model, info));
          }
        } else {
          const { targetRoot } = elements;
          render(getNow, targetRoot, dispatch, model, info, cmd.manageFocus);
        }
        return;
      }
      case "SendMessage": {
        const json = JSON.stringify(cmd.message);
        try {
          mutable.webSocket.send(json);
        } catch (error) {
          console.error("elm-watch: Failed to send WebSocket message:", error);
        }
        return;
      }
      case "SetBrowserUiPosition":
        if (elements !== void 0) {
          setBrowserUiPosition(cmd.browserUiPosition, elements);
        }
        return;
      case "SleepBeforeReconnect":
        setTimeout(() => {
          if (typeof document === "undefined" || document.visibilityState === "visible") {
            dispatch({ tag: "SleepBeforeReconnectDone", date: getNow() });
          }
        }, retryWaitMs(cmd.attemptNumber));
        return;
      case "TriggerReachedIdleState":
        Promise.resolve().then(() => {
          __ELM_WATCH.ON_REACHED_IDLE_STATE(cmd.reason);
        }).catch(rejectPromise);
        return;
      case "UpdateErrorOverlay":
        if (elements !== void 0) {
          updateErrorOverlay(
            TARGET_NAME,
            (msg) => {
              dispatch({ tag: "UiMsg", date: getNow(), msg });
            },
            cmd.sendKey,
            cmd.errors,
            elements.overlay,
            elements.overlayCloseButton
          );
        }
        return;
      case "UpdateGlobalStatus":
        __ELM_WATCH.RELOAD_STATUSES[TARGET_NAME] = cmd.reloadStatus;
        switch (cmd.reloadStatus.tag) {
          case "NoReloadWanted":
          case "MightWantToReload":
            break;
          case "ReloadRequested":
            try {
              window.sessionStorage.setItem(
                RELOAD_TARGET_NAME_KEY_PREFIX + TARGET_NAME,
                cmd.elmCompiledTimestamp.toString()
              );
            } catch {
            }
        }
        reloadPageIfNeeded();
        return;
      case "WebSocketTimeoutBegin":
        if (mutable.webSocketTimeoutId === void 0) {
          mutable.webSocketTimeoutId = setTimeout(() => {
            mutable.webSocketTimeoutId = void 0;
            mutable.webSocket.close();
            dispatch({
              tag: "WebSocketClosed",
              date: getNow()
            });
          }, __ELM_WATCH.WEBSOCKET_TIMEOUT);
        }
        return;
      case "WebSocketTimeoutClear":
        if (mutable.webSocketTimeoutId !== void 0) {
          clearTimeout(mutable.webSocketTimeoutId);
          mutable.webSocketTimeoutId = void 0;
        }
        return;
    }
  };
  function parseWebSocketMessageData(data) {
    try {
      return {
        tag: "Success",
        message: decodeWebSocketToClientMessage(string(data))
      };
    } catch (unknownError) {
      return {
        tag: "Error",
        message: `Failed to decode web socket message sent from the server:
${possiblyDecodeErrorToString(
          unknownError
        )}`
      };
    }
  }
  function possiblyDecodeErrorToString(unknownError) {
    return unknownError instanceof DecoderError ? unknownError.format() : unknownError instanceof Error ? unknownError.message : repr(unknownError);
  }
  function functionToNull(value) {
    return typeof value === "function" ? null : value;
  }
  var ProgramType = stringUnion({
    "Platform.worker": null,
    "Browser.sandbox": null,
    "Browser.element": null,
    "Browser.document": null,
    "Browser.application": null,
    Html: null
  });
  var ElmModule = chain(
    record(
      chain(
        functionToNull,
        multi({
          null: () => [],
          array: array(
            fields((field) => field("__elmWatchProgramType", ProgramType))
          ),
          object: (value) => ElmModule(value)
        })
      )
    ),
    (record2) => Object.values(record2).flat()
  );
  var ProgramTypes = fields((field) => field("Elm", ElmModule));
  function checkInitializedElmAppsStatus() {
    if (window.Elm !== void 0 && "__elmWatchProxy" in window.Elm) {
      return {
        tag: "DebuggerModeStatus",
        status: {
          tag: "Disabled",
          reason: noDebuggerYetReason
        }
      };
    }
    if (window.Elm === void 0) {
      return { tag: "MissingWindowElm" };
    }
    let programTypes;
    try {
      programTypes = ProgramTypes(window);
    } catch (unknownError) {
      return {
        tag: "DecodeError",
        message: possiblyDecodeErrorToString(unknownError)
      };
    }
    if (programTypes.length === 0) {
      return { tag: "NoProgramsAtAll" };
    }
    const noDebugger = programTypes.filter((programType) => {
      switch (programType) {
        case "Platform.worker":
        case "Html":
          return true;
        case "Browser.sandbox":
        case "Browser.element":
        case "Browser.document":
        case "Browser.application":
          return false;
      }
    });
    return {
      tag: "DebuggerModeStatus",
      status: noDebugger.length === programTypes.length ? {
        tag: "Disabled",
        reason: noDebuggerReason(new Set(noDebugger))
      } : { tag: "Enabled" }
    };
  }
  function reloadPageIfNeeded() {
    let shouldReload = false;
    const reasons = [];
    for (const [targetName, reloadStatus] of Object.entries(
      __ELM_WATCH.RELOAD_STATUSES
    )) {
      switch (reloadStatus.tag) {
        case "MightWantToReload":
          return;
        case "NoReloadWanted":
          break;
        case "ReloadRequested":
          shouldReload = true;
          if (reloadStatus.reasons.length > 0) {
            reasons.push([targetName, reloadStatus.reasons]);
          }
          break;
      }
    }
    if (!shouldReload) {
      return;
    }
    const first = reasons[0];
    const [separator, reasonString] = reasons.length === 1 && first !== void 0 && first[1].length === 1 ? [" ", `${first[1].join("")}
(target: ${first[0]})`] : [
      ":\n\n",
      reasons.map(
        ([targetName, subReasons]) => [
          targetName,
          ...subReasons.map((subReason) => `- ${subReason}`)
        ].join("\n")
      ).join("\n\n")
    ];
    const message = reasons.length === 0 ? void 0 : `elm-watch: I did a full page reload because${separator}${reasonString}`;
    __ELM_WATCH.RELOAD_STATUSES = {};
    __ELM_WATCH.RELOAD_PAGE(message);
  }
  function h(t, {
    attrs,
    style,
    localName,
    ...props
  }, ...children) {
    const element = document.createElement(
      localName ?? t.name.replace(/^HTML(\w+)Element$/, "$1").replace("Anchor", "a").replace("Paragraph", "p").replace(/^([DOU])List$/, "$1l").toLowerCase()
    );
    Object.assign(element, props);
    if (attrs !== void 0) {
      for (const [key, value] of Object.entries(attrs)) {
        element.setAttribute(key, value);
      }
    }
    if (style !== void 0) {
      for (const [key, value] of Object.entries(style)) {
        element.style[key] = value;
      }
    }
    for (const child of children) {
      if (child !== void 0) {
        element.append(
          typeof child === "string" ? document.createTextNode(child) : child
        );
      }
    }
    return element;
  }
  function renderWebWorker(model, info) {
    const statusData = statusIconAndText(model, info);
    return `${statusData.icon} elm-watch: ${statusData.status} ${formatTime(
      model.status.date
    )} (${info.targetName})`;
  }
  function render(getNow, targetRoot, dispatch, model, info, manageFocus) {
    targetRoot.replaceChildren(
      view(
        (msg) => {
          dispatch({ tag: "UiMsg", date: getNow(), msg });
        },
        model,
        info,
        manageFocus
      )
    );
    const firstFocusableElement = targetRoot.querySelector(`button, [tabindex]`);
    if (manageFocus && firstFocusableElement instanceof HTMLElement) {
      firstFocusableElement.focus();
    }
    __ELM_WATCH.ON_RENDER(TARGET_NAME);
  }
  var CLASS = {
    browserUiPositionButton: "browserUiPositionButton",
    browserUiPositionChooser: "browserUiPositionChooser",
    chevronButton: "chevronButton",
    compilationModeWithIcon: "compilationModeWithIcon",
    container: "container",
    debugModeIcon: "debugModeIcon",
    envNotSet: "envNotSet",
    errorLocationButton: "errorLocationButton",
    errorTitle: "errorTitle",
    expandedUiContainer: "expandedUiContainer",
    flashError: "flashError",
    flashSuccess: "flashSuccess",
    overlay: "overlay",
    overlayCloseButton: "overlayCloseButton",
    root: "root",
    rootBottomHalf: "rootBottomHalf",
    shortStatusContainer: "shortStatusContainer",
    targetName: "targetName",
    targetRoot: "targetRoot"
  };
  function getStatusClass({
    statusType,
    statusTypeChanged,
    hasReceivedHotReload,
    uiRelatedUpdate,
    errorOverlayVisible
  }) {
    switch (statusType) {
      case "Success":
        return statusTypeChanged && hasReceivedHotReload ? CLASS.flashSuccess : void 0;
      case "Error":
        return errorOverlayVisible ? statusTypeChanged && hasReceivedHotReload ? CLASS.flashError : void 0 : uiRelatedUpdate ? void 0 : CLASS.flashError;
      case "Waiting":
        return void 0;
    }
  }
  var CHEVRON_UP = "\u25B2";
  var CHEVRON_DOWN = "\u25BC";
  var CSS = `
input,
button,
select,
textarea {
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  letter-spacing: inherit;
  line-height: inherit;
  color: inherit;
  margin: 0;
}

fieldset {
  display: grid;
  gap: 0.25em;
  margin: 0;
  border: 1px solid var(--grey);
  padding: 0.25em 0.75em 0.5em;
}

fieldset:disabled {
  color: var(--grey);
}

p,
dd {
  margin: 0;
}

dl {
  display: grid;
  grid-template-columns: auto auto;
  gap: 0.25em 1em;
  margin: 0;
  white-space: nowrap;
}

dt {
  text-align: right;
  color: var(--grey);
}

time {
  display: inline-grid;
  overflow: hidden;
}

time::after {
  content: attr(data-format);
  visibility: hidden;
  height: 0;
}

.${CLASS.overlay} {
  position: fixed;
  z-index: -2;
  inset: 0;
  overflow-y: auto;
  padding: 2ch 0;
}

.${CLASS.overlayCloseButton} {
  position: fixed;
  z-index: -1;
  top: 0;
  right: 0;
  appearance: none;
  padding: 1em;
  border: none;
  border-radius: 0;
  background: none;
  cursor: pointer;
  font-size: 1.25em;
  filter: drop-shadow(0 0 0.125em var(--backgroundColor));
}

.${CLASS.overlayCloseButton}::before,
.${CLASS.overlayCloseButton}::after {
  content: "";
  display: block;
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0.125em;
  height: 1em;
  background-color: var(--foregroundColor);
  transform: translate(-50%, -50%) rotate(45deg);
}

.${CLASS.overlayCloseButton}::after {
  transform: translate(-50%, -50%) rotate(-45deg);
}

.${CLASS.overlay},
.${CLASS.overlay} pre {
  font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace;
}

.${CLASS.overlay} details {
  --border-thickness: 0.125em;
  border-top: var(--border-thickness) solid;
  margin: 2ch 0;
}

.${CLASS.overlay} summary {
  cursor: pointer;
  pointer-events: none;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  padding: 0 2ch;
  word-break: break-word;
}

.${CLASS.overlay} summary::-webkit-details-marker {
  display: none;
}

.${CLASS.overlay} summary::marker {
  content: none;
}

.${CLASS.overlay} summary > * {
  pointer-events: auto;
}

.${CLASS.errorTitle} {
  display: inline-block;
  font-weight: bold;
  --padding: 1ch;
  padding: 0 var(--padding);
  transform: translate(calc(var(--padding) * -1), calc(-50% - var(--border-thickness) / 2));
}

.${CLASS.errorTitle}::before {
  content: "${CHEVRON_DOWN}";
  display: inline-block;
  margin-right: 1ch;
  transform: translateY(-0.0625em);
}

details[open] > summary > .${CLASS.errorTitle}::before {
  content: "${CHEVRON_UP}";
}

.${CLASS.errorLocationButton} {
  appearance: none;
  padding: 0;
  border: none;
  border-radius: 0;
  background: none;
  text-align: left;
  text-decoration: underline;
  cursor: pointer;
}

.${CLASS.overlay} pre {
  margin: 0;
  padding: 2ch;
  overflow-x: auto;
}

.${CLASS.root} {
  --grey: #767676;
  display: flex;
  align-items: start;
  overflow: auto;
  max-height: 100vh;
  max-width: 100vw;
  color: black;
  font-family: system-ui;
}

.${CLASS.rootBottomHalf} {
  align-items: end;
}

.${CLASS.targetRoot} + .${CLASS.targetRoot} {
  margin-left: -1px;
}

.${CLASS.targetRoot}:only-of-type .${CLASS.debugModeIcon},
.${CLASS.targetRoot}:only-of-type .${CLASS.targetName} {
  display: none;
}

.${CLASS.container} {
  display: flex;
  flex-direction: column-reverse;
  background-color: white;
  border: 1px solid var(--grey);
}

.${CLASS.rootBottomHalf} .${CLASS.container} {
  flex-direction: column;
}

.${CLASS.envNotSet} {
  display: grid;
  gap: 0.75em;
  margin: 2em 0;
}

.${CLASS.envNotSet},
.${CLASS.root} pre {
  border-left: 0.25em solid var(--grey);
  padding-left: 0.5em;
}

.${CLASS.root} pre {
  margin: 0;
  white-space: pre-wrap;
}

.${CLASS.expandedUiContainer} {
  padding: 1em;
  padding-top: 0.75em;
  display: grid;
  gap: 0.75em;
  outline: none;
  contain: paint;
}

.${CLASS.rootBottomHalf} .${CLASS.expandedUiContainer} {
  padding-bottom: 0.75em;
}

.${CLASS.expandedUiContainer}:is(.length0, .length1) {
  grid-template-columns: min-content;
}

.${CLASS.expandedUiContainer} > dl {
  justify-self: start;
}

.${CLASS.expandedUiContainer} label {
  display: grid;
  grid-template-columns: min-content auto;
  align-items: center;
  gap: 0.25em;
}

.${CLASS.expandedUiContainer} label.Disabled {
  color: var(--grey);
}

.${CLASS.expandedUiContainer} label > small {
  grid-column: 2;
}

.${CLASS.compilationModeWithIcon} {
  display: flex;
  align-items: center;
  gap: 0.25em;
}

.${CLASS.browserUiPositionChooser} {
  position: absolute;
  display: grid;
  grid-template-columns: min-content min-content;
  pointer-events: none;
}

.${CLASS.browserUiPositionButton} {
  appearance: none;
  padding: 0;
  border: none;
  background: none;
  border-radius: none;
  pointer-events: auto;
  width: 1em;
  height: 1em;
  text-align: center;
  line-height: 1em;
}

.${CLASS.browserUiPositionButton}:hover {
  background-color: rgba(0, 0, 0, 0.25);
}

.${CLASS.targetRoot}:not(:first-child) .${CLASS.browserUiPositionChooser} {
  display: none;
}

.${CLASS.shortStatusContainer} {
  line-height: 1;
  padding: 0.25em;
  cursor: pointer;
  user-select: none;
  display: flex;
  align-items: center;
  gap: 0.25em;
}

.${CLASS.flashError}::before,
.${CLASS.flashSuccess}::before {
  content: "";
  position: absolute;
  margin-top: 0.5em;
  margin-left: 0.5em;
  --size: min(500px, 100vmin);
  width: var(--size);
  height: var(--size);
  border-radius: 50%;
  animation: flash 0.7s 0.05s ease-out both;
  pointer-events: none;
}

.${CLASS.flashError}::before {
  background-color: #eb0000;
}

.${CLASS.flashSuccess}::before {
  background-color: #00b600;
}

@keyframes flash {
  from {
    transform: translate(-50%, -50%) scale(0);
    opacity: 0.9;
  }

  to {
    transform: translate(-50%, -50%) scale(1);
    opacity: 0;
  }
}

@keyframes nudge {
  from {
    opacity: 0;
  }

  to {
    opacity: 0.8;
  }
}

@media (prefers-reduced-motion: reduce) {
  .${CLASS.flashError}::before,
  .${CLASS.flashSuccess}::before {
    transform: translate(-50%, -50%);
    width: 2em;
    height: 2em;
    animation: nudge 0.25s ease-in-out 4 alternate forwards;
  }
}

.${CLASS.chevronButton} {
  appearance: none;
  border: none;
  border-radius: 0;
  background: none;
  padding: 0;
  cursor: pointer;
}
`;
  function view(dispatch, passedModel, info, manageFocus) {
    const model = __ELM_WATCH.MOCKED_TIMINGS ? {
      ...passedModel,
      status: {
        ...passedModel.status,
        date: new Date("2022-02-05T13:10:05Z")
      }
    } : passedModel;
    const statusData = {
      ...statusIconAndText(model, info),
      ...viewStatus(dispatch, model, info)
    };
    const statusType = statusToStatusType(model.status.tag);
    const statusTypeChanged = statusType !== statusToStatusType(model.previousStatusTag);
    const statusClass = getStatusClass({
      statusType,
      statusTypeChanged,
      hasReceivedHotReload: model.elmCompiledTimestamp !== INITIAL_ELM_COMPILED_TIMESTAMP,
      uiRelatedUpdate: manageFocus,
      errorOverlayVisible: info.errorOverlayVisible
    });
    return h(
      HTMLDivElement,
      { className: CLASS.container },
      model.uiExpanded ? viewExpandedUi(
        model.status,
        statusData,
        info,
        model.browserUiPosition,
        dispatch
      ) : void 0,
      h(
        HTMLDivElement,
        {
          className: CLASS.shortStatusContainer,
          onclick: () => {
            dispatch({ tag: "PressedChevron" });
          }
        },
        h(
          HTMLButtonElement,
          {
            className: CLASS.chevronButton,
            attrs: { "aria-expanded": model.uiExpanded.toString() }
          },
          icon(
            model.uiExpanded ? CHEVRON_UP : CHEVRON_DOWN,
            model.uiExpanded ? "Collapse elm-watch" : "Expand elm-watch"
          )
        ),
        compilationModeIcon(model.compilationMode),
        icon(
          statusData.icon,
          statusData.status,
          statusClass === void 0 ? {} : {
            className: statusClass,
            onanimationend: (event) => {
              if (event.currentTarget instanceof HTMLElement) {
                event.currentTarget.classList.remove(statusClass);
              }
            }
          }
        ),
        h(
          HTMLTimeElement,
          { dateTime: model.status.date.toISOString() },
          formatTime(model.status.date)
        ),
        h(HTMLSpanElement, { className: CLASS.targetName }, TARGET_NAME)
      )
    );
  }
  function icon(emoji, alt, props) {
    return h(
      HTMLSpanElement,
      { attrs: { "aria-label": alt }, ...props },
      h(HTMLSpanElement, { attrs: { "aria-hidden": "true" } }, emoji)
    );
  }
  function viewExpandedUi(status, statusData, info, browserUiPosition, dispatch) {
    const items = [
      ["target", info.targetName],
      ["elm-watch", info.version],
      ["web socket", printWebSocketUrl(info.webSocketUrl)],
      [
        "updated",
        h(
          HTMLTimeElement,
          {
            dateTime: status.date.toISOString(),
            attrs: { "data-format": "2044-04-30 04:44:44" }
          },
          `${formatDate(status.date)} ${formatTime(status.date)}`
        )
      ],
      ["status", statusData.status],
      ...statusData.dl
    ];
    const browserUiPositionSendKey = statusToSpecialCaseSendKey(status);
    return h(
      HTMLDivElement,
      {
        className: `${CLASS.expandedUiContainer} length${statusData.content.length}`,
        attrs: {
          tabindex: "-1"
        }
      },
      h(
        HTMLDListElement,
        {},
        ...items.flatMap(([key, value]) => [
          h(HTMLElement, { localName: "dt" }, key),
          h(HTMLElement, { localName: "dd" }, value)
        ])
      ),
      ...statusData.content,
      browserUiPositionSendKey === void 0 ? void 0 : viewBrowserUiPositionChooser(
        browserUiPosition,
        dispatch,
        browserUiPositionSendKey
      )
    );
  }
  var allBrowserUiPositionsInOrder = [
    "TopLeft",
    "TopRight",
    "BottomLeft",
    "BottomRight"
  ];
  function viewBrowserUiPositionChooser(currentPosition, dispatch, sendKey) {
    const arrows = getBrowserUiPositionArrows(currentPosition);
    return h(
      HTMLDivElement,
      {
        className: CLASS.browserUiPositionChooser,
        style: browserUiPositionToCssForChooser(currentPosition)
      },
      ...allBrowserUiPositionsInOrder.map((position) => {
        const arrow = arrows[position];
        return arrow === void 0 ? h(HTMLDivElement, { style: { visibility: "hidden" } }, "\xB7") : h(
          HTMLButtonElement,
          {
            className: CLASS.browserUiPositionButton,
            attrs: { "data-position": position },
            onclick: () => {
              dispatch({
                tag: "ChangedBrowserUiPosition",
                browserUiPosition: position,
                sendKey
              });
            }
          },
          arrow
        );
      })
    );
  }
  var ARROW_UP = "\u2191";
  var ARROW_DOWN = "\u2193";
  var ARROW_LEFT = "\u2190";
  var ARROW_RIGHT = "\u2192";
  var ARROW_UP_LEFT = "\u2196";
  var ARROW_UP_RIGHT = "\u2197";
  var ARROW_DOWN_LEFT = "\u2199";
  var ARROW_DOWN_RIGHT = "\u2198";
  function getBrowserUiPositionArrows(browserUiPosition) {
    switch (browserUiPosition) {
      case "TopLeft":
        return {
          TopLeft: void 0,
          TopRight: ARROW_RIGHT,
          BottomLeft: ARROW_DOWN,
          BottomRight: ARROW_DOWN_RIGHT
        };
      case "TopRight":
        return {
          TopLeft: ARROW_LEFT,
          TopRight: void 0,
          BottomLeft: ARROW_DOWN_LEFT,
          BottomRight: ARROW_DOWN
        };
      case "BottomLeft":
        return {
          TopLeft: ARROW_UP,
          TopRight: ARROW_UP_RIGHT,
          BottomLeft: void 0,
          BottomRight: ARROW_RIGHT
        };
      case "BottomRight":
        return {
          TopLeft: ARROW_UP_LEFT,
          TopRight: ARROW_UP,
          BottomLeft: ARROW_LEFT,
          BottomRight: void 0
        };
    }
  }
  function statusIconAndText(model, info) {
    switch (model.status.tag) {
      case "Busy":
        return {
          icon: "\u23F3",
          status: "Waiting for compilation"
        };
      case "CompileError":
        return {
          icon: "\u{1F6A8}",
          status: "Compilation error"
        };
      case "Connecting":
        return {
          icon: "\u{1F50C}",
          status: "Connecting"
        };
      case "ElmJsonError":
        return {
          icon: "\u{1F6A8}",
          status: "elm.json or inputs error"
        };
      case "EvalError":
        return {
          icon: "\u26D4\uFE0F",
          status: "Eval error"
        };
      case "Idle":
        return {
          icon: idleIcon(info.initializedElmAppsStatus),
          status: "Successfully compiled"
        };
      case "SleepingBeforeReconnect":
        return {
          icon: "\u{1F50C}",
          status: "Sleeping"
        };
      case "UnexpectedError":
        return {
          icon: "\u274C",
          status: "Unexpected error"
        };
      case "WaitingForReload":
        return model.elmCompiledTimestamp === model.elmCompiledTimestampBeforeReload ? {
          icon: "\u274C",
          status: "Reload trouble"
        } : {
          icon: "\u23F3",
          status: "Waiting for reload"
        };
    }
  }
  function viewStatus(dispatch, model, info) {
    const { status, compilationMode } = model;
    switch (status.tag) {
      case "Busy":
        return {
          dl: [],
          content: [
            ...viewCompilationModeChooser({
              dispatch,
              sendKey: void 0,
              compilationMode,
              warnAboutCompilationModeMismatch: false,
              info
            }),
            ...status.errorOverlay === void 0 ? [] : [viewErrorOverlayToggleButton(dispatch, status.errorOverlay)]
          ]
        };
      case "CompileError":
        return {
          dl: [],
          content: [
            ...viewCompilationModeChooser({
              dispatch,
              sendKey: status.sendKey,
              compilationMode,
              warnAboutCompilationModeMismatch: true,
              info
            }),
            viewErrorOverlayToggleButton(dispatch, status.errorOverlay),
            ...status.openEditorError === void 0 ? [] : viewOpenEditorError(status.openEditorError)
          ]
        };
      case "Connecting":
        return {
          dl: [
            ["attempt", status.attemptNumber.toString()],
            ["sleep", printRetryWaitMs(status.attemptNumber)]
          ],
          content: [
            ...viewHttpsInfo(info.webSocketUrl),
            h(HTMLButtonElement, { disabled: true }, "Connecting web socket\u2026")
          ]
        };
      case "ElmJsonError":
        return {
          dl: [],
          content: [
            h(HTMLPreElement, { style: { minWidth: "80ch" } }, status.error)
          ]
        };
      case "EvalError":
        return {
          dl: [],
          content: [
            h(
              HTMLParagraphElement,
              {},
              "Check the console in the browser developer tools to see errors!"
            )
          ]
        };
      case "Idle":
        return {
          dl: [],
          content: viewCompilationModeChooser({
            dispatch,
            sendKey: status.sendKey,
            compilationMode,
            warnAboutCompilationModeMismatch: true,
            info
          })
        };
      case "SleepingBeforeReconnect":
        return {
          dl: [
            ["attempt", status.attemptNumber.toString()],
            ["sleep", printRetryWaitMs(status.attemptNumber)]
          ],
          content: [
            ...viewHttpsInfo(info.webSocketUrl),
            h(
              HTMLButtonElement,
              {
                onclick: () => {
                  dispatch({ tag: "PressedReconnectNow" });
                }
              },
              "Reconnect web socket now"
            )
          ]
        };
      case "UnexpectedError":
        return {
          dl: [],
          content: [
            h(
              HTMLParagraphElement,
              {},
              "I ran into an unexpected error! This is the error message:"
            ),
            h(HTMLPreElement, {}, status.message)
          ]
        };
      case "WaitingForReload":
        return {
          dl: [],
          content: model.elmCompiledTimestamp === model.elmCompiledTimestampBeforeReload ? [
            "A while ago I reloaded the page to get new compiled JavaScript.",
            "But it looks like after the last page reload I got the same JavaScript as before, instead of new stuff!",
            `The old JavaScript was compiled ${new Date(
              model.elmCompiledTimestamp
            ).toLocaleString()}, and so was the JavaScript currently running.`,
            "I currently need to reload the page again, but fear a reload loop if I try.",
            "Do you have accidental HTTP caching enabled maybe?",
            "Try hard refreshing the page and see if that helps, and consider disabling HTTP caching during development."
          ].map((text) => h(HTMLParagraphElement, {}, text)) : [h(HTMLParagraphElement, {}, "Waiting for other targets\u2026")]
        };
    }
  }
  function viewErrorOverlayToggleButton(dispatch, errorOverlay) {
    return h(
      HTMLButtonElement,
      {
        attrs: {
          "data-test-id": errorOverlay.openErrorOverlay ? "HideErrorOverlayButton" : "ShowErrorOverlayButton"
        },
        onclick: () => {
          dispatch({
            tag: "ChangedOpenErrorOverlay",
            openErrorOverlay: !errorOverlay.openErrorOverlay
          });
        }
      },
      errorOverlay.openErrorOverlay ? "Hide errors" : "Show errors"
    );
  }
  function viewOpenEditorError(error) {
    switch (error.tag) {
      case "EnvNotSet":
        return [
          h(
            HTMLDivElement,
            { className: CLASS.envNotSet },
            h(
              HTMLParagraphElement,
              {},
              "\u2139\uFE0F Clicking error locations only works if you set it up."
            ),
            h(
              HTMLParagraphElement,
              {},
              "Check this out: ",
              h(
                HTMLAnchorElement,
                {
                  href: "https://lydell.github.io/elm-watch/browser-ui/#clickable-error-locations",
                  target: "_blank",
                  rel: "noreferrer"
                },
                h(
                  HTMLElement,
                  { localName: "strong" },
                  "Clickable error locations"
                )
              )
            )
          )
        ];
      case "CommandFailed":
        return [
          h(
            HTMLParagraphElement,
            {},
            h(
              HTMLElement,
              { localName: "strong" },
              "Opening the location in your editor failed!"
            )
          ),
          h(HTMLPreElement, {}, error.message)
        ];
    }
  }
  function idleIcon(status) {
    switch (status.tag) {
      case "DecodeError":
      case "MissingWindowElm":
        return "\u274C";
      case "NoProgramsAtAll":
        return "\u2753";
      case "DebuggerModeStatus":
        return "\u2705";
    }
  }
  function compilationModeIcon(compilationMode) {
    switch (compilationMode) {
      case "proxy":
        return void 0;
      case "debug":
        return icon("\u{1F41B}", "Debug mode", { className: CLASS.debugModeIcon });
      case "standard":
        return void 0;
      case "optimize":
        return icon("\u{1F680}", "Optimize mode");
    }
  }
  function printWebSocketUrl(url) {
    const hostname = url.hostname.endsWith(".localhost") ? "localhost" : url.hostname;
    return `${url.protocol}//${hostname}:${url.port}`;
  }
  function viewHttpsInfo(webSocketUrl) {
    return webSocketUrl.protocol === "wss:" ? [
      h(
        HTMLParagraphElement,
        {},
        h(HTMLElement, { localName: "strong" }, "Having trouble connecting?")
      ),
      h(
        HTMLParagraphElement,
        {},
        " You might need to ",
        h(
          HTMLAnchorElement,
          { href: new URL(`https://${webSocketUrl.host}/accept`).href },
          "accept elm-watch\u2019s self-signed certificate"
        ),
        ". "
      ),
      h(
        HTMLParagraphElement,
        {},
        h(
          HTMLAnchorElement,
          {
            href: "https://lydell.github.io/elm-watch/https/",
            target: "_blank",
            rel: "noreferrer"
          },
          "More information"
        ),
        "."
      )
    ] : [];
  }
  var noDebuggerYetReason = "The Elm debugger isn't available at this point.";
  function noDebuggerReason(noDebuggerProgramTypes) {
    return `The Elm debugger isn't supported by ${humanList(
      Array.from(noDebuggerProgramTypes, (programType) => `\`${programType}\``),
      "and"
    )} programs.`;
  }
  function humanList(list, joinWord) {
    const { length } = list;
    return length <= 1 ? list.join("") : length === 2 ? list.join(` ${joinWord} `) : `${list.slice(0, length - 2).join(", ")}, ${list.slice(-2).join(` ${joinWord} `)}`;
  }
  function viewCompilationModeChooser({
    dispatch,
    sendKey,
    compilationMode: selectedMode,
    warnAboutCompilationModeMismatch,
    info
  }) {
    switch (info.initializedElmAppsStatus.tag) {
      case "DecodeError":
        return [
          h(
            HTMLParagraphElement,
            {},
            "window.Elm does not look like expected! This is the error message:"
          ),
          h(HTMLPreElement, {}, info.initializedElmAppsStatus.message)
        ];
      case "MissingWindowElm":
        return [
          h(
            HTMLParagraphElement,
            {},
            "elm-watch requires ",
            h(
              HTMLAnchorElement,
              {
                href: "https://lydell.github.io/elm-watch/window.Elm/",
                target: "_blank",
                rel: "noreferrer"
              },
              "window.Elm"
            ),
            " to exist, but it is undefined!"
          )
        ];
      case "NoProgramsAtAll":
        return [
          h(
            HTMLParagraphElement,
            {},
            "It looks like no Elm apps were initialized by elm-watch. Check the console in the browser developer tools to see potential errors!"
          )
        ];
      case "DebuggerModeStatus": {
        const compilationModes = [
          {
            mode: "debug",
            name: "Debug",
            status: info.initializedElmAppsStatus.status
          },
          { mode: "standard", name: "Standard", status: { tag: "Enabled" } },
          { mode: "optimize", name: "Optimize", status: { tag: "Enabled" } }
        ];
        return [
          h(
            HTMLFieldSetElement,
            { disabled: sendKey === void 0 },
            h(HTMLLegendElement, {}, "Compilation mode"),
            ...compilationModes.map(({ mode, name, status }) => {
              const nameWithIcon = h(
                HTMLSpanElement,
                { className: CLASS.compilationModeWithIcon },
                name,
                mode === selectedMode ? compilationModeIcon(mode) : void 0
              );
              return h(
                HTMLLabelElement,
                { className: status.tag },
                h(HTMLInputElement, {
                  type: "radio",
                  name: `CompilationMode-${info.targetName}`,
                  value: mode,
                  checked: mode === selectedMode,
                  disabled: sendKey === void 0 || status.tag === "Disabled",
                  onchange: sendKey === void 0 ? void 0 : () => {
                    dispatch({
                      tag: "ChangedCompilationMode",
                      compilationMode: mode,
                      sendKey
                    });
                  }
                }),
                ...status.tag === "Enabled" ? [
                  nameWithIcon,
                  warnAboutCompilationModeMismatch && mode === selectedMode && selectedMode !== info.originalCompilationMode && info.originalCompilationMode !== "proxy" ? h(
                    HTMLElement,
                    { localName: "small" },
                    `Note: The code currently running is in ${ORIGINAL_COMPILATION_MODE} mode.`
                  ) : void 0
                ] : [
                  nameWithIcon,
                  h(HTMLElement, { localName: "small" }, status.reason)
                ]
              );
            })
          )
        ];
      }
    }
  }
  var DATA_TARGET_NAMES = "data-target-names";
  function updateErrorOverlay(targetName, dispatch, sendKey, errors, overlay, overlayCloseButton) {
    const existingErrorElements = new Map(
      Array.from(overlay.children, (element) => [
        element.id,
        {
          targetNames: new Set(
            (element.getAttribute(DATA_TARGET_NAMES) ?? "").split("\n")
          ),
          element
        }
      ])
    );
    for (const [id, { targetNames, element }] of existingErrorElements) {
      if (targetNames.has(targetName) && !errors.has(id)) {
        targetNames.delete(targetName);
        if (targetNames.size === 0) {
          element.remove();
        } else {
          element.setAttribute(DATA_TARGET_NAMES, [...targetNames].join("\n"));
        }
      }
    }
    let previousElement = void 0;
    for (const [id, error] of errors) {
      const maybeExisting = existingErrorElements.get(id);
      if (maybeExisting === void 0) {
        const element = viewOverlayError(
          targetName,
          dispatch,
          sendKey,
          id,
          error
        );
        if (previousElement === void 0) {
          overlay.prepend(element);
        } else {
          previousElement.after(element);
        }
        overlay.style.backgroundColor = error.backgroundColor;
        overlayCloseButton.style.setProperty(
          "--foregroundColor",
          error.foregroundColor
        );
        overlayCloseButton.style.setProperty(
          "--backgroundColor",
          error.backgroundColor
        );
        previousElement = element;
      } else {
        if (!maybeExisting.targetNames.has(targetName)) {
          maybeExisting.element.setAttribute(
            DATA_TARGET_NAMES,
            [...maybeExisting.targetNames, targetName].join("\n")
          );
        }
        previousElement = maybeExisting.element;
      }
    }
    const hidden = !overlay.hasChildNodes();
    overlay.hidden = hidden;
    overlayCloseButton.hidden = hidden;
    overlayCloseButton.style.right = `${overlay.offsetWidth - overlay.clientWidth}px`;
  }
  function viewOverlayError(targetName, dispatch, sendKey, id, error) {
    return h(
      HTMLDetailsElement,
      {
        open: true,
        id,
        style: {
          backgroundColor: error.backgroundColor,
          color: error.foregroundColor
        },
        attrs: {
          [DATA_TARGET_NAMES]: targetName
        }
      },
      h(
        HTMLElement,
        { localName: "summary" },
        h(
          HTMLSpanElement,
          {
            className: CLASS.errorTitle,
            style: {
              backgroundColor: error.backgroundColor
            }
          },
          error.title
        ),
        error.location === void 0 ? void 0 : h(
          HTMLParagraphElement,
          {},
          viewErrorLocation(dispatch, sendKey, error.location)
        )
      ),
      h(HTMLPreElement, { innerHTML: error.htmlContent })
    );
  }
  function viewErrorLocation(dispatch, sendKey, location) {
    switch (location.tag) {
      case "FileOnly":
        return viewErrorLocationButton(
          dispatch,
          sendKey,
          {
            file: location.file,
            line: 1,
            column: 1
          },
          location.file.absolutePath
        );
      case "FileWithLineAndColumn": {
        return viewErrorLocationButton(
          dispatch,
          sendKey,
          location,
          `${location.file.absolutePath}:${location.line}:${location.column}`
        );
      }
      case "Target":
        return `Target: ${location.targetName}`;
    }
  }
  function viewErrorLocationButton(dispatch, sendKey, location, text) {
    return sendKey === void 0 ? text : h(
      HTMLButtonElement,
      {
        className: CLASS.errorLocationButton,
        onclick: () => {
          dispatch({
            tag: "PressedOpenEditor",
            file: location.file,
            line: location.line,
            column: location.column,
            sendKey
          });
        }
      },
      text
    );
  }
  if (typeof WebSocket !== "undefined") {
    run();
  }
})();
(function(scope){
'use strict';

var _Platform_effectManagers = {}, _Scheduler_enqueue; // added by elm-watch

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

console.warn('Compiled in DEV mode. Follow the advice at https://elm-lang.org/0.19.1/optimize for better performance and smaller assets.');


var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log_UNUSED = F2(function(tag, value)
{
	return value;
});

var _Debug_log = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString_UNUSED(value)
{
	return '<internals>';
}

function _Debug_toString(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash_UNUSED(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.start.line === region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'on lines ' + region.start.line + ' through ' + region.end.line;
}



// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**_UNUSED/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**_UNUSED/
	if (typeof x.$ === 'undefined')
	//*/
	/**/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0_UNUSED = 0;
var _Utils_Tuple0 = { $: '#0' };

function _Utils_Tuple2_UNUSED(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3_UNUSED(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr_UNUSED(c) { return c; }
function _Utils_chr(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil_UNUSED = { $: 0 };
var _List_Nil = { $: '[]' };

function _List_Cons_UNUSED(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap(value) { return { $: 0, a: value }; }
function _Json_unwrap(value) { return value.a; }

function _Json_wrap_UNUSED(value) { return value; }
function _Json_unwrap_UNUSED(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

// This function was slightly modified by elm-watch.
function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		// c: null // commented out by elm-watch
		c: Function.prototype // added by elm-watch
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			// }); // commented out by elm-watch
			}) || Function.prototype; // added by elm-watch
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


// This function was slightly modified by elm-watch.
var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		"Platform.worker", // added by elm-watch
		false, // isDebug, added by elm-watch
		debugMetadata, // added by elm-watch
		flagDecoder,
		args,
		impl.init,
		// impl.update, // commented out by elm-watch
		// impl.subscriptions, // commented out by elm-watch
		impl, // added by elm-watch
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


// This whole function was changed by elm-watch.
function _Platform_initialize(programType, isDebug, debugMetadata, flagDecoder, args, init, impl, stepperBuilder)
{
	if (args === "__elmWatchReturnData") {
		return { impl: impl, debugMetadata: debugMetadata, flagDecoder : flagDecoder, programType: programType };
	}

	var flags = _Json_wrap(args ? args['flags'] : undefined);
	var flagResult = A2(_Json_run, flagDecoder, flags);
	$elm$core$Result$isOk(flagResult) || _Debug_crash(2 /**/, _Json_errorToString(flagResult.a) /**/);
	var managers = {};
	var initUrl = programType === "Browser.application" ? _Browser_getUrl() : undefined;
	globalThis.__ELM_WATCH.INIT_URL = initUrl;
	var initPair = init(flagResult.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);
	var update;
	var subscriptions;

	function setUpdateAndSubscriptions() {
		update = impl.update || impl._impl.update;
		subscriptions = impl.subscriptions || impl._impl.subscriptions;
		if (isDebug) {
			update = $elm$browser$Debugger$Main$wrapUpdate(update);
			subscriptions = $elm$browser$Debugger$Main$wrapSubs(subscriptions);
		}
	}

	function sendToApp(msg, viewMetadata) {
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	setUpdateAndSubscriptions();
	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	function __elmWatchHotReload(newData, new_Platform_effectManagers, new_Scheduler_enqueue, moduleName) {
		_Platform_enqueueEffects(managers, _Platform_batch(_List_Nil), _Platform_batch(_List_Nil));
		_Scheduler_enqueue = new_Scheduler_enqueue;

		var reloadReasons = [];

		for (var key in new_Platform_effectManagers) {
			var manager = new_Platform_effectManagers[key];
			if (!(key in _Platform_effectManagers)) {
				_Platform_effectManagers[key] = manager;
				managers[key] = _Platform_instantiateManager(manager, sendToApp);
				if (manager.a) {
					reloadReasons.push("a new port '" + key + "' was added. The idea is to give JavaScript code a chance to set it up!");
					manager.a(key, sendToApp)
				}
			}
		}

		for (var key in newData.impl) {
			if (key === "_impl" && impl._impl) {
				for (var subKey in newData.impl[key]) {
					impl._impl[subKey] = newData.impl[key][subKey];
				}
			} else {
				impl[key] = newData.impl[key];
			}
		}

		var newFlagResult = A2(_Json_run, newData.flagDecoder, flags);
		if (!$elm$core$Result$isOk(newFlagResult)) {
			return reloadReasons.concat("the flags type in `" + moduleName + "` changed and now the passed flags aren't correct anymore. The idea is to try to run with new flags!\nThis is the error:\n" + _Json_errorToString(newFlagResult.a));
		}
		if (!_Utils_eq_elmWatchInternal(debugMetadata, newData.debugMetadata)) {
			return reloadReasons.concat("the message type in `" + moduleName + '` changed in debug mode ("debug metadata" changed).');
		}
		init = impl.init || impl._impl.init;
		if (isDebug) {
			init = A3($elm$browser$Debugger$Main$wrapInit, _Json_wrap(newData.debugMetadata), initPair.a.popout, init);
		}
		globalThis.__ELM_WATCH.INIT_URL = initUrl;
		var newInitPair = init(newFlagResult.a);
		if (!_Utils_eq_elmWatchInternal(initPair, newInitPair)) {
			return reloadReasons.concat("`" + moduleName + ".init` returned something different than last time. Let's start fresh!");
		}

		setUpdateAndSubscriptions();
		stepper(model, true /* isSync */);
		_Platform_enqueueEffects(managers, _Platform_batch(_List_Nil), subscriptions(model));
		return reloadReasons;
	}

	return Object.defineProperties(
		ports ? { ports: ports } : {},
		{
			__elmWatchHotReload: { value: __elmWatchHotReload },
			__elmWatchProgramType: { value: programType },
		}
	);
}

// This whole function was added by elm-watch.
// Copy-paste of _Utils_eq but does not assume that x and y have the same type,
// and considers functions to always be equal.
function _Utils_eq_elmWatchInternal(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp_elmWatchInternal(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp_elmWatchInternal(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

// This whole function was added by elm-watch.
function _Utils_eqHelp_elmWatchInternal(x, y, depth, stack)
{
	if (x === y) {
		return true;
	}

	var xType = _Utils_typeof_elmWatchInternal(x);
	var yType = _Utils_typeof_elmWatchInternal(y);

	if (xType !== yType) {
		return false;
	}

	switch (xType) {
		case "primitive":
			return false;
		case "function":
			return true;
	}

	if (x.$ !== y.$) {
		return false;
	}

	if (x.$ === 'Set_elm_builtin') {
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	} else if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin' || x.$ < 0) {
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}

	if (Object.keys(x).length !== Object.keys(y).length) {
		return false;
	}

	if (depth > 100) {
		stack.push(_Utils_Tuple2(x, y));
		return true;
	}

	for (var key in x) {
		if (!_Utils_eqHelp_elmWatchInternal(x[key], y[key], depth + 1, stack)) {
			return false;
		}
	}
	return true;
}

// This whole function was added by elm-watch.
function _Utils_typeof_elmWatchInternal(x)
{
	var type = typeof x;
	return type === "function"
		? "function"
		: type !== "object" || type === null
		? "primitive"
		: "objectOrArray";
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


// This whole function was changed by elm-watch.
function _Platform_export(exports)
{
	var reloadReasons = _Platform_mergeExportsElmWatch('Elm', scope['Elm'] || (scope['Elm'] = {}), exports);
	if (reloadReasons.length > 0) {
		throw new Error(["ELM_WATCH_RELOAD_NEEDED"].concat(Array.from(new Set(reloadReasons))).join("\n\n---\n\n"));
	}
}

// This whole function was added by elm-watch.
function _Platform_mergeExportsElmWatch(moduleName, obj, exports)
{
	var reloadReasons = [];
	for (var name in exports) {
		if (name === "init") {
			if ("init" in obj) {
				if ("__elmWatchApps" in obj) {
					var data = exports.init("__elmWatchReturnData");
					for (var index = 0; index < obj.__elmWatchApps.length; index++) {
						var app = obj.__elmWatchApps[index];
						if (app.__elmWatchProgramType !== data.programType) {
							reloadReasons.push("`" + moduleName + ".main` changed from `" + app.__elmWatchProgramType + "` to `" + data.programType + "`.");
						} else {
							try {
								var innerReasons = app.__elmWatchHotReload(data, _Platform_effectManagers, _Scheduler_enqueue, moduleName);
								reloadReasons = reloadReasons.concat(innerReasons);
							} catch (error) {
								reloadReasons.push("hot reload for `" + moduleName + "` failed, probably because of incompatible model changes.\nThis is the error:\n" + error + "\n" + (error ? error.stack : ""));
							}
						}
					}
				} else {
					throw new Error("elm-watch: I'm trying to create `" + moduleName + ".init`, but it already exists and wasn't created by elm-watch. Maybe a duplicate script is getting loaded accidentally?");
				}
			} else {
				obj.__elmWatchApps = [];
				obj.init = function() {
					var app = exports.init.apply(exports, arguments);
					obj.__elmWatchApps.push(app);
					globalThis.__ELM_WATCH.ON_INIT();
					return app;
				};
			}
		} else {
			var innerReasons = _Platform_mergeExportsElmWatch(moduleName + "." + name, obj[name] || (obj[name] = {}), exports[name]);
			reloadReasons = reloadReasons.concat(innerReasons);
		}
	}
	return reloadReasons;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

// This whole function was changed by elm-watch.
var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	var programType = "Html";

	if (args === "__elmWatchReturnData") {
		return { virtualNode: virtualNode, programType: programType };
	}

	/**_UNUSED/ // always UNUSED with elm-watch
	var node = args['node'];
	//*/
	/**/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	var nextNode = _VirtualDom_render(virtualNode, function() {});
	node.parentNode.replaceChild(nextNode, node);
	node = nextNode;
	var sendToApp = function() {};

	function __elmWatchHotReload(newData) {
		var patches = _VirtualDom_diff(virtualNode, newData.virtualNode);
		node = _VirtualDom_applyPatches(node, virtualNode, patches, sendToApp);
		virtualNode = newData.virtualNode;
		return [];
	}

	return Object.defineProperties(
		{},
		{
			__elmWatchHotReload: { value: __elmWatchHotReload },
			__elmWatchProgramType: { value: programType },
		}
	);
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		message: func(record.message),
		stopPropagation: record.stopPropagation,
		preventDefault: record.preventDefault
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.message;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.stopPropagation;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.preventDefault) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

// This function was slightly modified by elm-watch.
var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		impl._impl ? "Browser.sandbox" : "Browser.element", // added by elm-watch
		false, // isDebug, added by elm-watch
		debugMetadata, // added by elm-watch
		flagDecoder,
		args,
		impl.init,
		// impl.update, // commented out by elm-watch
		// impl.subscriptions, // commented out by elm-watch
		impl, // added by elm-watch
		function(sendToApp, initialModel) {
			// var view = impl.view; // commented out by elm-watch
			/**_UNUSED/ // always UNUSED with elm-watch
			var domNode = args['node'];
			//*/
			/**/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				// var nextNode = view(model); // commented out by elm-watch
				var nextNode = impl.view(model); // added by elm-watch
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

// This function was slightly modified by elm-watch.
var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		impl._impl ? "Browser.application" : "Browser.document", // added by elm-watch
		false, // isDebug, added by elm-watch
		debugMetadata, // added by elm-watch
		flagDecoder,
		args,
		impl.init,
		// impl.update, // commented out by elm-watch
		// impl.subscriptions, // commented out by elm-watch
		impl, // added by elm-watch
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.setup && impl.setup(sendToApp)
			// var view = impl.view; // commented out by elm-watch
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				// var doc = view(model); // commented out by elm-watch
				var doc = impl.view(model); // added by elm-watch
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.body);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.title) && (_VirtualDom_doc.title = title = doc.title);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


// This function was slightly modified by elm-watch.
function _Browser_application(impl)
{
	// var onUrlChange = impl.onUrlChange; // commented out by elm-watch
	// var onUrlRequest = impl.onUrlRequest; // commented out by elm-watch
	// var key = function() { key.a(onUrlChange(_Browser_getUrl())); }; // commented out by elm-watch
	var key = function() { key.a(impl.onUrlChange(_Browser_getUrl())); }; // added by elm-watch

	return _Browser_document({
		setup: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(impl.onUrlRequest(
						(next
							&& curr.protocol === next.protocol
							&& curr.host === next.host
							&& curr.port_.a === next.port_.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		init: function(flags)
		{
			// return A3(impl.init, flags, _Browser_getUrl(), key); // commented out by elm-watch
			return A3(impl.init, flags, globalThis.__ELM_WATCH.INIT_URL, key); // added by elm-watch
		},
		// view: impl.view, // commented out by elm-watch
		// update: impl.update, // commented out by elm-watch
		// subscriptions: impl.subscriptions // commented out by elm-watch
		view: function(model) { return impl.view(model); }, // added by elm-watch
		_impl: impl // added by elm-watch
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { hidden: 'hidden', change: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { hidden: 'mozHidden', change: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { hidden: 'msHidden', change: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { hidden: 'webkitHidden', change: 'webkitvisibilitychange' }
		: { hidden: 'hidden', change: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		scene: _Browser_getScene(),
		viewport: {
			x: _Browser_window.pageXOffset,
			y: _Browser_window.pageYOffset,
			width: _Browser_doc.documentElement.clientWidth,
			height: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		width: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		height: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			scene: {
				width: node.scrollWidth,
				height: node.scrollHeight
			},
			viewport: {
				x: node.scrollLeft,
				y: node.scrollTop,
				width: node.clientWidth,
				height: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			scene: _Browser_getScene(),
			viewport: {
				x: x,
				y: y,
				width: _Browser_doc.documentElement.clientWidth,
				height: _Browser_doc.documentElement.clientHeight
			},
			element: {
				x: x + rect.left,
				y: y + rect.top,
				width: rect.width,
				height: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}


function _Url_percentEncode(string)
{
	return encodeURIComponent(string);
}

function _Url_percentDecode(string)
{
	try
	{
		return $elm$core$Maybe$Just(decodeURIComponent(string));
	}
	catch (e)
	{
		return $elm$core$Maybe$Nothing;
	}
}


function _Time_now(millisToPosix)
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(millisToPosix(Date.now())));
	});
}

var _Time_setInterval = F2(function(interval, task)
{
	return _Scheduler_binding(function(callback)
	{
		var id = setInterval(function() { _Scheduler_rawSpawn(task); }, interval);
		return function() { clearInterval(id); };
	});
});

function _Time_here()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(
			A2($elm$time$Time$customZone, -(new Date().getTimezoneOffset()), _List_Nil)
		));
	});
}


function _Time_getZoneName()
{
	return _Scheduler_binding(function(callback)
	{
		try
		{
			var name = $elm$time$Time$Name(Intl.DateTimeFormat().resolvedOptions().timeZone);
		}
		catch (e)
		{
			var name = $elm$time$Time$Offset(new Date().getTimezoneOffset());
		}
		callback(_Scheduler_succeed(name));
	});
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});


// CREATE

var _Regex_never = /.^/;

var _Regex_fromStringWith = F2(function(options, string)
{
	var flags = 'g';
	if (options.multiline) { flags += 'm'; }
	if (options.caseInsensitive) { flags += 'i'; }

	try
	{
		return $elm$core$Maybe$Just(new RegExp(string, flags));
	}
	catch(error)
	{
		return $elm$core$Maybe$Nothing;
	}
});


// USE

var _Regex_contains = F2(function(re, string)
{
	return string.match(re) !== null;
});


var _Regex_findAtMost = F3(function(n, re, str)
{
	var out = [];
	var number = 0;
	var string = str;
	var lastIndex = re.lastIndex;
	var prevLastIndex = -1;
	var result;
	while (number++ < n && (result = re.exec(string)))
	{
		if (prevLastIndex == re.lastIndex) break;
		var i = result.length - 1;
		var subs = new Array(i);
		while (i > 0)
		{
			var submatch = result[i];
			subs[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		out.push(A4($elm$regex$Regex$Match, result[0], result.index, number, _List_fromArray(subs)));
		prevLastIndex = re.lastIndex;
	}
	re.lastIndex = lastIndex;
	return _List_fromArray(out);
});


var _Regex_replaceAtMost = F4(function(n, re, replacer, string)
{
	var count = 0;
	function jsReplacer(match)
	{
		if (count++ >= n)
		{
			return match;
		}
		var i = arguments.length - 3;
		var submatches = new Array(i);
		while (i > 0)
		{
			var submatch = arguments[i];
			submatches[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		return replacer(A4($elm$regex$Regex$Match, match, arguments[arguments.length - 2], count, _List_fromArray(submatches)));
	}
	return string.replace(re, jsReplacer);
});

var _Regex_splitAtMost = F3(function(n, re, str)
{
	var string = str;
	var out = [];
	var start = re.lastIndex;
	var restoreLastIndex = re.lastIndex;
	while (n--)
	{
		var result = re.exec(string);
		if (!result) break;
		out.push(string.slice(start, result.index));
		start = re.lastIndex;
	}
	out.push(string.slice(start));
	re.lastIndex = restoreLastIndex;
	return _List_fromArray(out);
});

var _Regex_infinity = Infinity;



// SEND REQUEST

var _Http_toTask = F3(function(router, toTask, request)
{
	return _Scheduler_binding(function(callback)
	{
		function done(response) {
			callback(toTask(request.expect.a(response)));
		}

		var xhr = new XMLHttpRequest();
		xhr.addEventListener('error', function() { done($elm$http$Http$NetworkError_); });
		xhr.addEventListener('timeout', function() { done($elm$http$Http$Timeout_); });
		xhr.addEventListener('load', function() { done(_Http_toResponse(request.expect.b, xhr)); });
		$elm$core$Maybe$isJust(request.tracker) && _Http_track(router, xhr, request.tracker.a);

		try {
			xhr.open(request.method, request.url, true);
		} catch (e) {
			return done($elm$http$Http$BadUrl_(request.url));
		}

		_Http_configureRequest(xhr, request);

		request.body.a && xhr.setRequestHeader('Content-Type', request.body.a);
		xhr.send(request.body.b);

		return function() { xhr.c = true; xhr.abort(); };
	});
});


// CONFIGURE

function _Http_configureRequest(xhr, request)
{
	for (var headers = request.headers; headers.b; headers = headers.b) // WHILE_CONS
	{
		xhr.setRequestHeader(headers.a.a, headers.a.b);
	}
	xhr.timeout = request.timeout.a || 0;
	xhr.responseType = request.expect.d;
	xhr.withCredentials = request.allowCookiesFromOtherDomains;
}


// RESPONSES

function _Http_toResponse(toBody, xhr)
{
	return A2(
		200 <= xhr.status && xhr.status < 300 ? $elm$http$Http$GoodStatus_ : $elm$http$Http$BadStatus_,
		_Http_toMetadata(xhr),
		toBody(xhr.response)
	);
}


// METADATA

function _Http_toMetadata(xhr)
{
	return {
		url: xhr.responseURL,
		statusCode: xhr.status,
		statusText: xhr.statusText,
		headers: _Http_parseHeaders(xhr.getAllResponseHeaders())
	};
}


// HEADERS

function _Http_parseHeaders(rawHeaders)
{
	if (!rawHeaders)
	{
		return $elm$core$Dict$empty;
	}

	var headers = $elm$core$Dict$empty;
	var headerPairs = rawHeaders.split('\r\n');
	for (var i = headerPairs.length; i--; )
	{
		var headerPair = headerPairs[i];
		var index = headerPair.indexOf(': ');
		if (index > 0)
		{
			var key = headerPair.substring(0, index);
			var value = headerPair.substring(index + 2);

			headers = A3($elm$core$Dict$update, key, function(oldValue) {
				return $elm$core$Maybe$Just($elm$core$Maybe$isJust(oldValue)
					? value + ', ' + oldValue.a
					: value
				);
			}, headers);
		}
	}
	return headers;
}


// EXPECT

var _Http_expect = F3(function(type, toBody, toValue)
{
	return {
		$: 0,
		d: type,
		b: toBody,
		a: toValue
	};
});

var _Http_mapExpect = F2(function(func, expect)
{
	return {
		$: 0,
		d: expect.d,
		b: expect.b,
		a: function(x) { return func(expect.a(x)); }
	};
});

function _Http_toDataView(arrayBuffer)
{
	return new DataView(arrayBuffer);
}


// BODY and PARTS

var _Http_emptyBody = { $: 0 };
var _Http_pair = F2(function(a, b) { return { $: 0, a: a, b: b }; });

function _Http_toFormData(parts)
{
	for (var formData = new FormData(); parts.b; parts = parts.b) // WHILE_CONS
	{
		var part = parts.a;
		formData.append(part.a, part.b);
	}
	return formData;
}

var _Http_bytesToBlob = F2(function(mime, bytes)
{
	return new Blob([bytes], { type: mime });
});


// PROGRESS

function _Http_track(router, xhr, tracker)
{
	// TODO check out lengthComputable on loadstart event

	xhr.upload.addEventListener('progress', function(event) {
		if (xhr.c) { return; }
		_Scheduler_rawSpawn(A2($elm$core$Platform$sendToSelf, router, _Utils_Tuple2(tracker, $elm$http$Http$Sending({
			sent: event.loaded,
			size: event.total
		}))));
	});
	xhr.addEventListener('progress', function(event) {
		if (xhr.c) { return; }
		_Scheduler_rawSpawn(A2($elm$core$Platform$sendToSelf, router, _Utils_Tuple2(tracker, $elm$http$Http$Receiving({
			received: event.loaded,
			size: event.lengthComputable ? $elm$core$Maybe$Just(event.total) : $elm$core$Maybe$Nothing
		}))));
	});
}var $elm$core$Maybe$Just = function (a) {
	return {$: 'Just', a: a};
};
var $author$project$Main$LinkClicked = function (a) {
	return {$: 'LinkClicked', a: a};
};
var $elm$core$Maybe$Nothing = {$: 'Nothing'};
var $author$project$Main$UrlChanged = function (a) {
	return {$: 'UrlChanged', a: a};
};
var $elm$core$List$cons = _List_cons;
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (node.$ === 'SubTree') {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0.a;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Basics$EQ = {$: 'EQ'};
var $elm$core$Basics$GT = {$: 'GT'};
var $elm$core$Basics$LT = {$: 'LT'};
var $elm$core$Result$Err = function (a) {
	return {$: 'Err', a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 'Failure', a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 'Index', a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 'Ok', a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 'OneOf', a: a};
};
var $elm$core$Basics$False = {$: 'False'};
var $elm$core$Basics$add = _Basics_add;
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 'Field':
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 'Nothing') {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'Index':
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'OneOf':
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 'Array_elm_builtin', a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 'Leaf', a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 'SubTree', a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.nodeListSize) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.tail);
		} else {
			var treeLen = builder.nodeListSize * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.nodeList) : builder.nodeList;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.nodeListSize);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.tail);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{nodeList: nodeList, nodeListSize: (len / $elm$core$Array$branchFactor) | 0, tail: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = {$: 'True'};
var $elm$core$Result$isOk = function (result) {
	if (result.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 'Normal':
			return 0;
		case 'MayStopPropagation':
			return 1;
		case 'MayPreventDefault':
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 'External', a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 'Internal', a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = function (a) {
	return {$: 'NotFound', a: a};
};
var $elm$url$Url$Http = {$: 'Http'};
var $elm$url$Url$Https = {$: 'Https'};
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {fragment: fragment, host: host, path: path, port_: port_, protocol: protocol, query: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 'Nothing') {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Http,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Https,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0.a;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = function (a) {
	return {$: 'Perform', a: a};
};
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(_Utils_Tuple0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0.a;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return _Utils_Tuple0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(_Utils_Tuple0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0.a;
		return $elm$core$Task$Perform(
			A2($elm$core$Task$map, tagger, task));
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2($elm$core$Task$map, toMessage, task)));
	});
var $elm$browser$Browser$application = _Browser_application;
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$json$Json$Decode$index = _Json_decodeIndex;
var $author$project$Main$GotViewport = function (a) {
	return {$: 'GotViewport', a: a};
};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$HostConfig$pathSegments = function (path) {
	return A2(
		$elm$core$List$filter,
		function (segment) {
			return segment !== '';
		},
		A2($elm$core$String$split, '/', path));
};
var $author$project$HostConfig$protocolToString = function (protocol) {
	if (protocol.$ === 'Http') {
		return 'http://';
	} else {
		return 'https://';
	}
};
var $author$project$HostConfig$rebuildRoot = F3(
	function (protocol, host, port_) {
		return _Utils_ap(
			$author$project$HostConfig$protocolToString(protocol),
			_Utils_ap(
				host,
				function () {
					if (port_.$ === 'Just') {
						var portNumber = port_.a;
						return ':' + $elm$core$String$fromInt(portNumber);
					} else {
						return '';
					}
				}()));
	});
var $author$project$HostConfig$fromApiBaseUrl = function (apiBaseUrl) {
	var _v0 = $elm$url$Url$fromString(apiBaseUrl);
	if (_v0.$ === 'Just') {
		var protocol = _v0.a.protocol;
		var host = _v0.a.host;
		var path = _v0.a.path;
		var port_ = _v0.a.port_;
		return _Utils_Tuple2(
			A3($author$project$HostConfig$rebuildRoot, protocol, host, port_),
			$author$project$HostConfig$pathSegments(path));
	} else {
		return _Utils_Tuple2(
			'',
			$author$project$HostConfig$pathSegments(apiBaseUrl));
	}
};
var $elm$browser$Browser$Dom$getViewport = _Browser_withWindow(_Browser_getViewport);
var $elm$url$Url$Parser$State = F5(
	function (visited, unvisited, params, frag, value) {
		return {frag: frag, params: params, unvisited: unvisited, value: value, visited: visited};
	});
var $elm$url$Url$Parser$getFirstMatch = function (states) {
	getFirstMatch:
	while (true) {
		if (!states.b) {
			return $elm$core$Maybe$Nothing;
		} else {
			var state = states.a;
			var rest = states.b;
			var _v1 = state.unvisited;
			if (!_v1.b) {
				return $elm$core$Maybe$Just(state.value);
			} else {
				if ((_v1.a === '') && (!_v1.b.b)) {
					return $elm$core$Maybe$Just(state.value);
				} else {
					var $temp$states = rest;
					states = $temp$states;
					continue getFirstMatch;
				}
			}
		}
	}
};
var $elm$url$Url$Parser$removeFinalEmpty = function (segments) {
	if (!segments.b) {
		return _List_Nil;
	} else {
		if ((segments.a === '') && (!segments.b.b)) {
			return _List_Nil;
		} else {
			var segment = segments.a;
			var rest = segments.b;
			return A2(
				$elm$core$List$cons,
				segment,
				$elm$url$Url$Parser$removeFinalEmpty(rest));
		}
	}
};
var $elm$url$Url$Parser$preparePath = function (path) {
	var _v0 = A2($elm$core$String$split, '/', path);
	if (_v0.b && (_v0.a === '')) {
		var segments = _v0.b;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	} else {
		var segments = _v0;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	}
};
var $elm$url$Url$Parser$addToParametersHelp = F2(
	function (value, maybeList) {
		if (maybeList.$ === 'Nothing') {
			return $elm$core$Maybe$Just(
				_List_fromArray(
					[value]));
		} else {
			var list = maybeList.a;
			return $elm$core$Maybe$Just(
				A2($elm$core$List$cons, value, list));
		}
	});
var $elm$url$Url$percentDecode = _Url_percentDecode;
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1.$) {
					case 'LT':
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 'EQ':
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Dict$Black = {$: 'Black'};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: 'RBNode_elm_builtin', a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$RBEmpty_elm_builtin = {$: 'RBEmpty_elm_builtin'};
var $elm$core$Dict$Red = {$: 'Red'};
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Red')) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) && (left.d.$ === 'RBNode_elm_builtin')) && (left.d.a.$ === 'Red')) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1.$) {
				case 'LT':
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 'EQ':
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.e.d.$ === 'RBNode_elm_builtin') && (dict.e.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.d.d.$ === 'RBNode_elm_builtin') && (dict.d.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Black')) {
					if (right.d.$ === 'RBNode_elm_builtin') {
						if (right.d.a.$ === 'Black') {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor.$ === 'Black') {
			if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === 'RBNode_elm_builtin') {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Black')) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === 'RBNode_elm_builtin') {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBNode_elm_builtin') {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === 'RBNode_elm_builtin') {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (_v0.$ === 'Just') {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $elm$url$Url$Parser$addParam = F2(
	function (segment, dict) {
		var _v0 = A2($elm$core$String$split, '=', segment);
		if ((_v0.b && _v0.b.b) && (!_v0.b.b.b)) {
			var rawKey = _v0.a;
			var _v1 = _v0.b;
			var rawValue = _v1.a;
			var _v2 = $elm$url$Url$percentDecode(rawKey);
			if (_v2.$ === 'Nothing') {
				return dict;
			} else {
				var key = _v2.a;
				var _v3 = $elm$url$Url$percentDecode(rawValue);
				if (_v3.$ === 'Nothing') {
					return dict;
				} else {
					var value = _v3.a;
					return A3(
						$elm$core$Dict$update,
						key,
						$elm$url$Url$Parser$addToParametersHelp(value),
						dict);
				}
			}
		} else {
			return dict;
		}
	});
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$url$Url$Parser$prepareQuery = function (maybeQuery) {
	if (maybeQuery.$ === 'Nothing') {
		return $elm$core$Dict$empty;
	} else {
		var qry = maybeQuery.a;
		return A3(
			$elm$core$List$foldr,
			$elm$url$Url$Parser$addParam,
			$elm$core$Dict$empty,
			A2($elm$core$String$split, '&', qry));
	}
};
var $elm$url$Url$Parser$parse = F2(
	function (_v0, url) {
		var parser = _v0.a;
		return $elm$url$Url$Parser$getFirstMatch(
			parser(
				A5(
					$elm$url$Url$Parser$State,
					_List_Nil,
					$elm$url$Url$Parser$preparePath(url.path),
					$elm$url$Url$Parser$prepareQuery(url.query),
					url.fragment,
					$elm$core$Basics$identity)));
	});
var $author$project$Main$TravellerPage = {$: 'TravellerPage'};
var $elm$url$Url$Parser$Parser = function (a) {
	return {$: 'Parser', a: a};
};
var $elm$url$Url$Parser$mapState = F2(
	function (func, _v0) {
		var visited = _v0.visited;
		var unvisited = _v0.unvisited;
		var params = _v0.params;
		var frag = _v0.frag;
		var value = _v0.value;
		return A5(
			$elm$url$Url$Parser$State,
			visited,
			unvisited,
			params,
			frag,
			func(value));
	});
var $elm$url$Url$Parser$map = F2(
	function (subValue, _v0) {
		var parseArg = _v0.a;
		return $elm$url$Url$Parser$Parser(
			function (_v1) {
				var visited = _v1.visited;
				var unvisited = _v1.unvisited;
				var params = _v1.params;
				var frag = _v1.frag;
				var value = _v1.value;
				return A2(
					$elm$core$List$map,
					$elm$url$Url$Parser$mapState(value),
					parseArg(
						A5($elm$url$Url$Parser$State, visited, unvisited, params, frag, subValue)));
			});
	});
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $elm$url$Url$Parser$oneOf = function (parsers) {
	return $elm$url$Url$Parser$Parser(
		function (state) {
			return A2(
				$elm$core$List$concatMap,
				function (_v0) {
					var parser = _v0.a;
					return parser(state);
				},
				parsers);
		});
};
var $elm$url$Url$Parser$top = $elm$url$Url$Parser$Parser(
	function (state) {
		return _List_fromArray(
			[state]);
	});
var $author$project$Main$routeParser = $elm$url$Url$Parser$oneOf(
	_List_fromArray(
		[
			A2($elm$url$Url$Parser$map, $author$project$Main$TravellerPage, $elm$url$Url$Parser$top)
		]));
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Main$init = F3(
	function (flags, url, key) {
		var hostConfig = $author$project$HostConfig$fromApiBaseUrl(flags.apiBaseUrl);
		var model = {
			dialogBody: $elm$html$Html$text('Error dialog'),
			flags: flags,
			hostConfig: hostConfig,
			isDarkMode: false,
			key: key,
			referee: flags.referee,
			route: A2($elm$url$Url$Parser$parse, $author$project$Main$routeParser, url),
			travellerModel: $elm$core$Maybe$Nothing,
			url: url
		};
		return _Utils_Tuple2(
			model,
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[
						A2($elm$core$Task$perform, $author$project$Main$GotViewport, $elm$browser$Browser$Dom$getViewport)
					])));
	});
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $elm$json$Json$Decode$null = _Json_decodeNull;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Main$GotTravellerMsg = function (a) {
	return {$: 'GotTravellerMsg', a: a};
};
var $elm$core$Debug$log = _Debug_log;
var $elm$core$Platform$Sub$map = _Platform_map;
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$core$Platform$Sub$none = $elm$core$Platform$Sub$batch(_List_Nil);
var $author$project$Traveller$GotResize = F2(
	function (a, b) {
		return {$: 'GotResize', a: a, b: b};
	});
var $author$project$Traveller$Tick = function (a) {
	return {$: 'Tick', a: a};
};
var $elm$time$Time$Every = F2(
	function (a, b) {
		return {$: 'Every', a: a, b: b};
	});
var $elm$time$Time$State = F2(
	function (taggers, processes) {
		return {processes: processes, taggers: taggers};
	});
var $elm$time$Time$init = $elm$core$Task$succeed(
	A2($elm$time$Time$State, $elm$core$Dict$empty, $elm$core$Dict$empty));
var $elm$time$Time$addMySub = F2(
	function (_v0, state) {
		var interval = _v0.a;
		var tagger = _v0.b;
		var _v1 = A2($elm$core$Dict$get, interval, state);
		if (_v1.$ === 'Nothing') {
			return A3(
				$elm$core$Dict$insert,
				interval,
				_List_fromArray(
					[tagger]),
				state);
		} else {
			var taggers = _v1.a;
			return A3(
				$elm$core$Dict$insert,
				interval,
				A2($elm$core$List$cons, tagger, taggers),
				state);
		}
	});
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$time$Time$Name = function (a) {
	return {$: 'Name', a: a};
};
var $elm$time$Time$Offset = function (a) {
	return {$: 'Offset', a: a};
};
var $elm$time$Time$Zone = F2(
	function (a, b) {
		return {$: 'Zone', a: a, b: b};
	});
var $elm$time$Time$customZone = $elm$time$Time$Zone;
var $elm$time$Time$setInterval = _Time_setInterval;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$time$Time$spawnHelp = F3(
	function (router, intervals, processes) {
		if (!intervals.b) {
			return $elm$core$Task$succeed(processes);
		} else {
			var interval = intervals.a;
			var rest = intervals.b;
			var spawnTimer = $elm$core$Process$spawn(
				A2(
					$elm$time$Time$setInterval,
					interval,
					A2($elm$core$Platform$sendToSelf, router, interval)));
			var spawnRest = function (id) {
				return A3(
					$elm$time$Time$spawnHelp,
					router,
					rest,
					A3($elm$core$Dict$insert, interval, id, processes));
			};
			return A2($elm$core$Task$andThen, spawnRest, spawnTimer);
		}
	});
var $elm$time$Time$onEffects = F3(
	function (router, subs, _v0) {
		var processes = _v0.processes;
		var rightStep = F3(
			function (_v6, id, _v7) {
				var spawns = _v7.a;
				var existing = _v7.b;
				var kills = _v7.c;
				return _Utils_Tuple3(
					spawns,
					existing,
					A2(
						$elm$core$Task$andThen,
						function (_v5) {
							return kills;
						},
						$elm$core$Process$kill(id)));
			});
		var newTaggers = A3($elm$core$List$foldl, $elm$time$Time$addMySub, $elm$core$Dict$empty, subs);
		var leftStep = F3(
			function (interval, taggers, _v4) {
				var spawns = _v4.a;
				var existing = _v4.b;
				var kills = _v4.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, interval, spawns),
					existing,
					kills);
			});
		var bothStep = F4(
			function (interval, taggers, id, _v3) {
				var spawns = _v3.a;
				var existing = _v3.b;
				var kills = _v3.c;
				return _Utils_Tuple3(
					spawns,
					A3($elm$core$Dict$insert, interval, id, existing),
					kills);
			});
		var _v1 = A6(
			$elm$core$Dict$merge,
			leftStep,
			bothStep,
			rightStep,
			newTaggers,
			processes,
			_Utils_Tuple3(
				_List_Nil,
				$elm$core$Dict$empty,
				$elm$core$Task$succeed(_Utils_Tuple0)));
		var spawnList = _v1.a;
		var existingDict = _v1.b;
		var killTask = _v1.c;
		return A2(
			$elm$core$Task$andThen,
			function (newProcesses) {
				return $elm$core$Task$succeed(
					A2($elm$time$Time$State, newTaggers, newProcesses));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v2) {
					return A3($elm$time$Time$spawnHelp, router, spawnList, existingDict);
				},
				killTask));
	});
var $elm$time$Time$Posix = function (a) {
	return {$: 'Posix', a: a};
};
var $elm$time$Time$millisToPosix = $elm$time$Time$Posix;
var $elm$time$Time$now = _Time_now($elm$time$Time$millisToPosix);
var $elm$time$Time$onSelfMsg = F3(
	function (router, interval, state) {
		var _v0 = A2($elm$core$Dict$get, interval, state.taggers);
		if (_v0.$ === 'Nothing') {
			return $elm$core$Task$succeed(state);
		} else {
			var taggers = _v0.a;
			var tellTaggers = function (time) {
				return $elm$core$Task$sequence(
					A2(
						$elm$core$List$map,
						function (tagger) {
							return A2(
								$elm$core$Platform$sendToApp,
								router,
								tagger(time));
						},
						taggers));
			};
			return A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$succeed(state);
				},
				A2($elm$core$Task$andThen, tellTaggers, $elm$time$Time$now));
		}
	});
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$time$Time$subMap = F2(
	function (f, _v0) {
		var interval = _v0.a;
		var tagger = _v0.b;
		return A2(
			$elm$time$Time$Every,
			interval,
			A2($elm$core$Basics$composeL, f, tagger));
	});
_Platform_effectManagers['Time'] = _Platform_createManager($elm$time$Time$init, $elm$time$Time$onEffects, $elm$time$Time$onSelfMsg, 0, $elm$time$Time$subMap);
var $elm$time$Time$subscription = _Platform_leaf('Time');
var $elm$time$Time$every = F2(
	function (interval, tagger) {
		return $elm$time$Time$subscription(
			A2($elm$time$Time$Every, interval, tagger));
	});
var $author$project$Traveller$CloseObjectAnalysis = {$: 'CloseObjectAnalysis'};
var $author$project$Traveller$NoOpMsg = {$: 'NoOpMsg'};
var $author$project$Traveller$toKey = F2(
	function (model, string) {
		var _v0 = _Utils_Tuple2(model.objectToBeAnalyzed, string);
		if ((_v0.a.$ === 'Just') && (_v0.b === 'Escape')) {
			return $author$project$Traveller$CloseObjectAnalysis;
		} else {
			return $author$project$Traveller$NoOpMsg;
		}
	});
var $author$project$Traveller$keyDecoder = function (model) {
	return A2(
		$elm$json$Json$Decode$map,
		$author$project$Traveller$toKey(model),
		A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string));
};
var $elm$browser$Browser$Events$Document = {$: 'Document'};
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 'MySub', a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {pids: pids, subs: subs};
	});
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (node.$ === 'Document') {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {event: event, key: key};
	});
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (node.$ === 'Document') {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.pids,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (_v0.$ === 'Just') {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.key;
		var event = _v0.event;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.subs);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onKeyDown = A2($elm$browser$Browser$Events$on, $elm$browser$Browser$Events$Document, 'keydown');
var $elm$browser$Browser$Events$Window = {$: 'Window'};
var $elm$browser$Browser$Events$onResize = function (func) {
	return A3(
		$elm$browser$Browser$Events$on,
		$elm$browser$Browser$Events$Window,
		'resize',
		A2(
			$elm$json$Json$Decode$field,
			'target',
			A3(
				$elm$json$Json$Decode$map2,
				func,
				A2($elm$json$Json$Decode$field, 'innerWidth', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'innerHeight', $elm$json$Json$Decode$int))));
};
var $author$project$Traveller$subscriptions = F2(
	function (time, model) {
		return $elm$core$Platform$Sub$batch(
			_List_fromArray(
				[
					$elm$browser$Browser$Events$onResize($author$project$Traveller$GotResize),
					$elm$browser$Browser$Events$onKeyDown(
					$author$project$Traveller$keyDecoder(model)),
					A2($elm$time$Time$every, (1 / 30) * 1000, $author$project$Traveller$Tick)
				]));
	});
var $author$project$Main$subscriptions = function (_v0) {
	var travellerModel = _v0.travellerModel;
	if (travellerModel.$ === 'Just') {
		var _v2 = travellerModel.a;
		var t = _v2.a;
		var tm = _v2.b;
		return A2(
			$elm$core$Platform$Sub$map,
			$author$project$Main$GotTravellerMsg,
			A2($author$project$Traveller$subscriptions, t, tm));
	} else {
		return A2($elm$core$Debug$log, 'Ignored subscription', $elm$core$Platform$Sub$none);
	}
};
var $author$project$Traveller$GotViewport = function (a) {
	return {$: 'GotViewport', a: a};
};
var $author$project$Traveller$HexAddress$HexAddress = F2(
	function (x, y) {
		return {x: x, y: y};
	});
var $author$project$Traveller$HexMap = {$: 'HexMap'};
var $author$project$Traveller$NoDragging = {$: 'NoDragging'};
var $author$project$Traveller$defaultHexRectSize = 30;
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $krisajenkins$remotedata$RemoteData$Loading = {$: 'Loading'};
var $author$project$Traveller$LoadingSolarSystem = {$: 'LoadingSolarSystem'};
var $author$project$Traveller$HexAddress$between = F2(
	function (upperLeftHex, lowerRightHex) {
		return A2(
			$elm$core$List$concatMap,
			function (x) {
				return A2(
					$elm$core$List$map,
					function (y) {
						return {x: x, y: y};
					},
					A2($elm$core$List$range, lowerRightHex.y, upperLeftHex.y));
			},
			A2($elm$core$List$range, upperLeftHex.x, lowerRightHex.x));
	});
var $author$project$Traveller$MkRequestNum = function (a) {
	return {$: 'MkRequestNum', a: a};
};
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$core$List$maximum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$max, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Traveller$nextRequestNum = function (requestHistory) {
	var lastRequestNum = function () {
		if (!requestHistory.b) {
			return 0;
		} else {
			var requests = requestHistory;
			return A2(
				$elm$core$Maybe$withDefault,
				0,
				$elm$core$List$maximum(
					A2(
						$elm$core$List$map,
						A2(
							$elm$core$Basics$composeR,
							function ($) {
								return $.requestNum;
							},
							function (_v1) {
								var x = _v1.a;
								return x;
							}),
						requests)));
		}
	}();
	return $author$project$Traveller$MkRequestNum(lastRequestNum + 1);
};
var $author$project$Traveller$HexAddress$toKey = function (_v0) {
	var x = _v0.x;
	var y = _v0.y;
	return $elm$core$String$fromInt(x) + ('.' + $elm$core$String$fromInt(y));
};
var $author$project$Traveller$prepNextRequest = F2(
	function (_v0, _v1) {
		var oldSolarSystemDict = _v0.a;
		var requestHistory = _v0.b;
		var upperLeftHex = _v1.upperLeftHex;
		var lowerRightHex = _v1.lowerRightHex;
		var requestNum = $author$project$Traveller$nextRequestNum(requestHistory);
		var requestEntry = {lowerRightHex: lowerRightHex, requestNum: requestNum, status: $krisajenkins$remotedata$RemoteData$Loading, upperLeftHex: upperLeftHex};
		var newSolarSystemDict = function () {
			var markSolarSystemLoadingIfNotFound = function (maybeSolarSystem) {
				if (maybeSolarSystem.$ === 'Just') {
					var existingSolarSystem = maybeSolarSystem.a;
					return $elm$core$Maybe$Just(existingSolarSystem);
				} else {
					return $elm$core$Maybe$Just($author$project$Traveller$LoadingSolarSystem);
				}
			};
			return A3(
				$elm$core$List$foldl,
				F2(
					function (hexAddr, solarSystemDict) {
						return A3(
							$elm$core$Dict$update,
							$author$project$Traveller$HexAddress$toKey(hexAddr),
							markSolarSystemLoadingIfNotFound,
							solarSystemDict);
					}),
				oldSolarSystemDict,
				A2($author$project$Traveller$HexAddress$between, upperLeftHex, lowerRightHex));
		}();
		return _Utils_Tuple2(
			requestEntry,
			_Utils_Tuple2(
				newSolarSystemDict,
				A2($elm$core$List$cons, requestEntry, requestHistory)));
	});
var $elm$core$Basics$cos = _Basics_cos;
var $elm$core$Basics$pi = _Basics_pi;
var $author$project$Traveller$HexGeometry$hexSizeFactor = (2 * $elm$core$Basics$pi) / 6;
var $elm$core$Basics$sin = _Basics_sin;
var $author$project$Traveller$HexGeometry$rawHexagonPoint = F2(
	function (size, n) {
		var y = size * $elm$core$Basics$sin($author$project$Traveller$HexGeometry$hexSizeFactor * n);
		var x = size * $elm$core$Basics$cos($author$project$Traveller$HexGeometry$hexSizeFactor * n);
		return _Utils_Tuple2(x, y);
	});
var $author$project$Traveller$HexGeometry$rawHexagonPoints = function (size) {
	return A2(
		$elm$core$List$map,
		A2(
			$elm$core$Basics$composeR,
			$elm$core$Basics$toFloat,
			$author$project$Traveller$HexGeometry$rawHexagonPoint(size)),
		A2($elm$core$List$range, 0, 5));
};
var $author$project$Traveller$DownloadedRegions = F2(
	function (a, b) {
		return {$: 'DownloadedRegions', a: a, b: b};
	});
var $author$project$Traveller$Region$Region = F5(
	function (id, colour, name, labelPosition, hexes) {
		return {colour: colour, hexes: hexes, id: id, labelPosition: labelPosition, name: name};
	});
var $miniBill$elm_codec$Codec$Codec = function (a) {
	return {$: 'Codec', a: a};
};
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(_Utils_Tuple0),
			pairs));
};
var $miniBill$elm_codec$Codec$buildObject = function (_v0) {
	var om = _v0.a;
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: om.decoder,
			encoder: function (v) {
				return $elm$json$Json$Encode$object(
					$elm$core$List$reverse(
						om.encoder(v)));
			}
		});
};
var $miniBill$elm_codec$Codec$ObjectCodec = function (a) {
	return {$: 'ObjectCodec', a: a};
};
var $miniBill$elm_codec$Codec$decoder = function (_v0) {
	var m = _v0.a;
	return m.decoder;
};
var $miniBill$elm_codec$Codec$encoder = function (_v0) {
	var m = _v0.a;
	return m.encoder;
};
var $miniBill$elm_codec$Codec$field = F4(
	function (name, getter, codec, _v0) {
		var ocodec = _v0.a;
		return $miniBill$elm_codec$Codec$ObjectCodec(
			{
				decoder: A3(
					$elm$json$Json$Decode$map2,
					F2(
						function (f, x) {
							return f(x);
						}),
					ocodec.decoder,
					A2(
						$elm$json$Json$Decode$field,
						name,
						$miniBill$elm_codec$Codec$decoder(codec))),
				encoder: function (v) {
					return A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							name,
							A2(
								$miniBill$elm_codec$Codec$encoder,
								codec,
								getter(v))),
						ocodec.encoder(v));
				}
			});
	});
var $miniBill$elm_codec$Codec$build = F2(
	function (encoder_, decoder_) {
		return $miniBill$elm_codec$Codec$Codec(
			{decoder: decoder_, encoder: encoder_});
	});
var $elm$json$Json$Encode$int = _Json_wrap;
var $miniBill$elm_codec$Codec$int = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$int, $elm$json$Json$Decode$int);
var $miniBill$elm_codec$Codec$object = function (ctor) {
	return $miniBill$elm_codec$Codec$ObjectCodec(
		{
			decoder: $elm$json$Json$Decode$succeed(ctor),
			encoder: function (_v0) {
				return _List_Nil;
			}
		});
};
var $author$project$Traveller$HexAddress$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'y',
		function ($) {
			return $.y;
		},
		$miniBill$elm_codec$Codec$int,
		A4(
			$miniBill$elm_codec$Codec$field,
			'x',
			function ($) {
				return $.x;
			},
			$miniBill$elm_codec$Codec$int,
			$miniBill$elm_codec$Codec$object($author$project$Traveller$HexAddress$HexAddress))));
var $miniBill$elm_codec$Codec$andThen = F3(
	function (dec, enc, c) {
		return $miniBill$elm_codec$Codec$Codec(
			{
				decoder: A2(
					$elm$json$Json$Decode$andThen,
					A2($elm$core$Basics$composeR, dec, $miniBill$elm_codec$Codec$decoder),
					$miniBill$elm_codec$Codec$decoder(c)),
				encoder: A2(
					$elm$core$Basics$composeL,
					$miniBill$elm_codec$Codec$encoder(c),
					enc)
			});
	});
var $elm$core$Basics$round = _Basics_round;
var $elm$core$String$cons = _String_cons;
var $elm$core$String$fromChar = function (_char) {
	return A2($elm$core$String$cons, _char, '');
};
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Bitwise$shiftRightBy = _Bitwise_shiftRightBy;
var $elm$core$String$repeatHelp = F3(
	function (n, chunk, result) {
		return (n <= 0) ? result : A3(
			$elm$core$String$repeatHelp,
			n >> 1,
			_Utils_ap(chunk, chunk),
			(!(n & 1)) ? result : _Utils_ap(result, chunk));
	});
var $elm$core$String$repeat = F2(
	function (n, chunk) {
		return A3($elm$core$String$repeatHelp, n, chunk, '');
	});
var $elm$core$String$padLeft = F3(
	function (n, _char, string) {
		return _Utils_ap(
			A2(
				$elm$core$String$repeat,
				n - $elm$core$String$length(string),
				$elm$core$String$fromChar(_char)),
			string);
	});
var $elm$core$Char$fromCode = _Char_fromCode;
var $elm$core$Basics$modBy = _Basics_modBy;
var $noahzgordon$elm_color_extra$Color$Convert$toRadix = function (n) {
	var getChr = function (c) {
		return (c < 10) ? $elm$core$String$fromInt(c) : $elm$core$String$fromChar(
			$elm$core$Char$fromCode(87 + c));
	};
	return (n < 16) ? getChr(n) : _Utils_ap(
		$noahzgordon$elm_color_extra$Color$Convert$toRadix((n / 16) | 0),
		getChr(
			A2($elm$core$Basics$modBy, 16, n)));
};
var $noahzgordon$elm_color_extra$Color$Convert$toHex = A2(
	$elm$core$Basics$composeR,
	$noahzgordon$elm_color_extra$Color$Convert$toRadix,
	A2(
		$elm$core$String$padLeft,
		2,
		_Utils_chr('0')));
var $avh4$elm_color$Color$toRgba = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	return {alpha: a, blue: b, green: g, red: r};
};
var $noahzgordon$elm_color_extra$Color$Convert$colorToHex = function (cl) {
	var _v0 = $avh4$elm_color$Color$toRgba(cl);
	var red = _v0.red;
	var green = _v0.green;
	var blue = _v0.blue;
	return A2(
		$elm$core$String$join,
		'',
		A2(
			$elm$core$List$cons,
			'#',
			A2(
				$elm$core$List$map,
				A2($elm$core$Basics$composeR, $elm$core$Basics$round, $noahzgordon$elm_color_extra$Color$Convert$toHex),
				_List_fromArray(
					[red * 255, green * 255, blue * 255]))));
};
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $elm$json$Json$Decode$fail = _Json_fail;
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $miniBill$elm_codec$Codec$fail = function (msg) {
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: $elm$json$Json$Decode$fail(msg),
			encoder: $elm$core$Basics$always($elm$json$Json$Encode$null)
		});
};
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (maybeValue.$ === 'Just') {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Result$andThen = F2(
	function (callback, result) {
		if (result.$ === 'Ok') {
			var value = result.a;
			return callback(value);
		} else {
			var msg = result.a;
			return $elm$core$Result$Err(msg);
		}
	});
var $elm$regex$Regex$Match = F4(
	function (match, index, number, submatches) {
		return {index: index, match: match, number: number, submatches: submatches};
	});
var $elm$regex$Regex$findAtMost = _Regex_findAtMost;
var $elm$core$String$fromList = _String_fromList;
var $elm$core$Result$fromMaybe = F2(
	function (err, maybe) {
		if (maybe.$ === 'Just') {
			var v = maybe.a;
			return $elm$core$Result$Ok(v);
		} else {
			return $elm$core$Result$Err(err);
		}
	});
var $elm$regex$Regex$fromStringWith = _Regex_fromStringWith;
var $elm$regex$Regex$fromString = function (string) {
	return A2(
		$elm$regex$Regex$fromStringWith,
		{caseInsensitive: false, multiline: false},
		string);
};
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Result$map = F2(
	function (func, ra) {
		if (ra.$ === 'Ok') {
			var a = ra.a;
			return $elm$core$Result$Ok(
				func(a));
		} else {
			var e = ra.a;
			return $elm$core$Result$Err(e);
		}
	});
var $fredcy$elm_parseint$ParseInt$InvalidRadix = function (a) {
	return {$: 'InvalidRadix', a: a};
};
var $fredcy$elm_parseint$ParseInt$InvalidChar = function (a) {
	return {$: 'InvalidChar', a: a};
};
var $fredcy$elm_parseint$ParseInt$OutOfRange = function (a) {
	return {$: 'OutOfRange', a: a};
};
var $fredcy$elm_parseint$ParseInt$charOffset = F2(
	function (basis, c) {
		return $elm$core$Char$toCode(c) - $elm$core$Char$toCode(basis);
	});
var $fredcy$elm_parseint$ParseInt$isBetween = F3(
	function (lower, upper, c) {
		var ci = $elm$core$Char$toCode(c);
		return (_Utils_cmp(
			$elm$core$Char$toCode(lower),
			ci) < 1) && (_Utils_cmp(
			ci,
			$elm$core$Char$toCode(upper)) < 1);
	});
var $fredcy$elm_parseint$ParseInt$intFromChar = F2(
	function (radix, c) {
		var validInt = function (i) {
			return (_Utils_cmp(i, radix) < 0) ? $elm$core$Result$Ok(i) : $elm$core$Result$Err(
				$fredcy$elm_parseint$ParseInt$OutOfRange(c));
		};
		var toInt = A3(
			$fredcy$elm_parseint$ParseInt$isBetween,
			_Utils_chr('0'),
			_Utils_chr('9'),
			c) ? $elm$core$Result$Ok(
			A2(
				$fredcy$elm_parseint$ParseInt$charOffset,
				_Utils_chr('0'),
				c)) : (A3(
			$fredcy$elm_parseint$ParseInt$isBetween,
			_Utils_chr('a'),
			_Utils_chr('z'),
			c) ? $elm$core$Result$Ok(
			10 + A2(
				$fredcy$elm_parseint$ParseInt$charOffset,
				_Utils_chr('a'),
				c)) : (A3(
			$fredcy$elm_parseint$ParseInt$isBetween,
			_Utils_chr('A'),
			_Utils_chr('Z'),
			c) ? $elm$core$Result$Ok(
			10 + A2(
				$fredcy$elm_parseint$ParseInt$charOffset,
				_Utils_chr('A'),
				c)) : $elm$core$Result$Err(
			$fredcy$elm_parseint$ParseInt$InvalidChar(c))));
		return A2($elm$core$Result$andThen, validInt, toInt);
	});
var $fredcy$elm_parseint$ParseInt$parseIntR = F2(
	function (radix, rstring) {
		var _v0 = $elm$core$String$uncons(rstring);
		if (_v0.$ === 'Nothing') {
			return $elm$core$Result$Ok(0);
		} else {
			var _v1 = _v0.a;
			var c = _v1.a;
			var rest = _v1.b;
			return A2(
				$elm$core$Result$andThen,
				function (ci) {
					return A2(
						$elm$core$Result$andThen,
						function (ri) {
							return $elm$core$Result$Ok(ci + (ri * radix));
						},
						A2($fredcy$elm_parseint$ParseInt$parseIntR, radix, rest));
				},
				A2($fredcy$elm_parseint$ParseInt$intFromChar, radix, c));
		}
	});
var $elm$core$String$reverse = _String_reverse;
var $fredcy$elm_parseint$ParseInt$parseIntRadix = F2(
	function (radix, string) {
		return ((2 <= radix) && (radix <= 36)) ? A2(
			$fredcy$elm_parseint$ParseInt$parseIntR,
			radix,
			$elm$core$String$reverse(string)) : $elm$core$Result$Err(
			$fredcy$elm_parseint$ParseInt$InvalidRadix(radix));
	});
var $fredcy$elm_parseint$ParseInt$parseIntHex = $fredcy$elm_parseint$ParseInt$parseIntRadix(16);
var $avh4$elm_color$Color$RgbaSpace = F4(
	function (a, b, c, d) {
		return {$: 'RgbaSpace', a: a, b: b, c: c, d: d};
	});
var $avh4$elm_color$Color$rgb = F3(
	function (r, g, b) {
		return A4($avh4$elm_color$Color$RgbaSpace, r, g, b, 1.0);
	});
var $avh4$elm_color$Color$rgba = F4(
	function (r, g, b, a) {
		return A4($avh4$elm_color$Color$RgbaSpace, r, g, b, a);
	});
var $elm$core$Basics$pow = _Basics_pow;
var $noahzgordon$elm_color_extra$Color$Convert$roundToPlaces = F2(
	function (places, number) {
		var multiplier = A2($elm$core$Basics$pow, 10, places);
		return $elm$core$Basics$round(number * multiplier) / multiplier;
	});
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $elm$core$String$toLower = _String_toLower;
var $noahzgordon$elm_color_extra$Color$Convert$hexToColor = function () {
	var pattern = '' + ('^' + ('#?' + ('(?:' + ('(?:([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2}))' + ('|' + ('(?:([a-f\\d])([a-f\\d])([a-f\\d]))' + ('|' + ('(?:([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2}))' + ('|' + ('(?:([a-f\\d])([a-f\\d])([a-f\\d])([a-f\\d]))' + (')' + '$')))))))))));
	var extend = function (token) {
		var _v6 = $elm$core$String$toList(token);
		if (_v6.b && (!_v6.b.b)) {
			var token_ = _v6.a;
			return $elm$core$String$fromList(
				_List_fromArray(
					[token_, token_]));
		} else {
			return token;
		}
	};
	return A2(
		$elm$core$Basics$composeR,
		$elm$core$String$toLower,
		A2(
			$elm$core$Basics$composeR,
			function (str) {
				return A2(
					$elm$core$Maybe$map,
					function (regex) {
						return A3($elm$regex$Regex$findAtMost, 1, regex, str);
					},
					$elm$regex$Regex$fromString(pattern));
			},
			A2(
				$elm$core$Basics$composeR,
				$elm$core$Maybe$andThen($elm$core$List$head),
				A2(
					$elm$core$Basics$composeR,
					$elm$core$Maybe$map(
						function ($) {
							return $.submatches;
						}),
					A2(
						$elm$core$Basics$composeR,
						$elm$core$Maybe$map(
							$elm$core$List$filterMap($elm$core$Basics$identity)),
						A2(
							$elm$core$Basics$composeR,
							$elm$core$Result$fromMaybe('Parsing hex regex failed'),
							$elm$core$Result$andThen(
								function (colors) {
									var _v0 = A2(
										$elm$core$List$map,
										A2(
											$elm$core$Basics$composeR,
											extend,
											A2(
												$elm$core$Basics$composeR,
												$fredcy$elm_parseint$ParseInt$parseIntHex,
												$elm$core$Result$map($elm$core$Basics$toFloat))),
										colors);
									_v0$2:
									while (true) {
										if (((((_v0.b && (_v0.a.$ === 'Ok')) && _v0.b.b) && (_v0.b.a.$ === 'Ok')) && _v0.b.b.b) && (_v0.b.b.a.$ === 'Ok')) {
											if (_v0.b.b.b.b) {
												if ((_v0.b.b.b.a.$ === 'Ok') && (!_v0.b.b.b.b.b)) {
													var r = _v0.a.a;
													var _v1 = _v0.b;
													var g = _v1.a.a;
													var _v2 = _v1.b;
													var b = _v2.a.a;
													var _v3 = _v2.b;
													var a = _v3.a.a;
													return $elm$core$Result$Ok(
														A4(
															$avh4$elm_color$Color$rgba,
															r / 255,
															g / 255,
															b / 255,
															A2($noahzgordon$elm_color_extra$Color$Convert$roundToPlaces, 2, a / 255)));
												} else {
													break _v0$2;
												}
											} else {
												var r = _v0.a.a;
												var _v4 = _v0.b;
												var g = _v4.a.a;
												var _v5 = _v4.b;
												var b = _v5.a.a;
												return $elm$core$Result$Ok(
													A3($avh4$elm_color$Color$rgb, r / 255, g / 255, b / 255));
											}
										} else {
											break _v0$2;
										}
									}
									return $elm$core$Result$Err('Parsing ints from hex failed');
								})))))));
}();
var $elm$json$Json$Encode$string = _Json_wrap;
var $miniBill$elm_codec$Codec$string = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$string, $elm$json$Json$Decode$string);
var $miniBill$elm_codec$Codec$succeed = function (default_) {
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: $elm$json$Json$Decode$succeed(default_),
			encoder: function (_v0) {
				return $elm$json$Json$Encode$null;
			}
		});
};
var $author$project$Traveller$Region$codecColour = A3(
	$miniBill$elm_codec$Codec$andThen,
	function (s) {
		var _v0 = $noahzgordon$elm_color_extra$Color$Convert$hexToColor(s);
		if (_v0.$ === 'Ok') {
			var color = _v0.a;
			return $miniBill$elm_codec$Codec$succeed(color);
		} else {
			var errString = _v0.a;
			return $miniBill$elm_codec$Codec$fail(errString);
		}
	},
	function (c) {
		return $noahzgordon$elm_color_extra$Color$Convert$colorToHex(c);
	},
	$miniBill$elm_codec$Codec$string);
var $miniBill$elm_codec$Codec$composite = F3(
	function (enc, dec, _v0) {
		var codec = _v0.a;
		return $miniBill$elm_codec$Codec$Codec(
			{
				decoder: dec(codec.decoder),
				encoder: enc(codec.encoder)
			});
	});
var $elm$json$Json$Decode$list = _Json_decodeList;
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(_Utils_Tuple0),
				entries));
	});
var $miniBill$elm_codec$Codec$list = A2($miniBill$elm_codec$Codec$composite, $elm$json$Json$Encode$list, $elm$json$Json$Decode$list);
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 'Nothing') {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 'Nothing') {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $miniBill$elm_codec$Codec$maybe = function (codec) {
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: $elm$json$Json$Decode$maybe(
				$miniBill$elm_codec$Codec$decoder(codec)),
			encoder: function (v) {
				if (v.$ === 'Nothing') {
					return $elm$json$Json$Encode$null;
				} else {
					var x = v.a;
					return A2($miniBill$elm_codec$Codec$encoder, codec, x);
				}
			}
		});
};
var $author$project$Traveller$Region$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'hexes',
		function ($) {
			return $.hexes;
		},
		$miniBill$elm_codec$Codec$list($author$project$Traveller$HexAddress$codec),
		A4(
			$miniBill$elm_codec$Codec$field,
			'name',
			function ($) {
				return $.name;
			},
			$miniBill$elm_codec$Codec$string,
			A4(
				$miniBill$elm_codec$Codec$field,
				'colour',
				function ($) {
					return $.colour;
				},
				$author$project$Traveller$Region$codecColour,
				A4(
					$miniBill$elm_codec$Codec$field,
					'id',
					function ($) {
						return $.id;
					},
					$miniBill$elm_codec$Codec$int,
					A4(
						$miniBill$elm_codec$Codec$field,
						'label_y',
						A2(
							$elm$core$Basics$composeR,
							function ($) {
								return $.labelPosition;
							},
							$elm$core$Maybe$map(
								function ($) {
									return $.y;
								})),
						$miniBill$elm_codec$Codec$maybe($miniBill$elm_codec$Codec$int),
						A4(
							$miniBill$elm_codec$Codec$field,
							'label_x',
							A2(
								$elm$core$Basics$composeR,
								function ($) {
									return $.labelPosition;
								},
								$elm$core$Maybe$map(
									function ($) {
										return $.x;
									})),
							$miniBill$elm_codec$Codec$maybe($miniBill$elm_codec$Codec$int),
							$miniBill$elm_codec$Codec$object(
								F6(
									function (mx, my, id, colour, name, hexes) {
										return A5(
											$author$project$Traveller$Region$Region,
											id,
											colour,
											name,
											A3(
												$elm$core$Maybe$map2,
												F2(
													function (x, y) {
														return {x: x, y: y};
													}),
												mx,
												my),
											hexes);
									})))))))));
var $elm$url$Url$Builder$toQueryPair = function (_v0) {
	var key = _v0.a;
	var value = _v0.b;
	return key + ('=' + value);
};
var $elm$url$Url$Builder$toQuery = function (parameters) {
	if (!parameters.b) {
		return '';
	} else {
		return '?' + A2(
			$elm$core$String$join,
			'&',
			A2($elm$core$List$map, $elm$url$Url$Builder$toQueryPair, parameters));
	}
};
var $elm$url$Url$Builder$crossOrigin = F3(
	function (prePath, pathSegments, parameters) {
		return prePath + ('/' + (A2($elm$core$String$join, '/', pathSegments) + $elm$url$Url$Builder$toQuery(parameters)));
	});
var $elm$http$Http$BadStatus_ = F2(
	function (a, b) {
		return {$: 'BadStatus_', a: a, b: b};
	});
var $elm$http$Http$BadUrl_ = function (a) {
	return {$: 'BadUrl_', a: a};
};
var $elm$http$Http$GoodStatus_ = F2(
	function (a, b) {
		return {$: 'GoodStatus_', a: a, b: b};
	});
var $elm$http$Http$NetworkError_ = {$: 'NetworkError_'};
var $elm$http$Http$Receiving = function (a) {
	return {$: 'Receiving', a: a};
};
var $elm$http$Http$Sending = function (a) {
	return {$: 'Sending', a: a};
};
var $elm$http$Http$Timeout_ = {$: 'Timeout_'};
var $elm$core$Maybe$isJust = function (maybe) {
	if (maybe.$ === 'Just') {
		return true;
	} else {
		return false;
	}
};
var $elm$http$Http$emptyBody = _Http_emptyBody;
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$http$Http$expectStringResponse = F2(
	function (toMsg, toResult) {
		return A3(
			_Http_expect,
			'',
			$elm$core$Basics$identity,
			A2($elm$core$Basics$composeR, toResult, toMsg));
	});
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (result.$ === 'Ok') {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $elm$http$Http$BadBody = function (a) {
	return {$: 'BadBody', a: a};
};
var $elm$http$Http$BadStatus = function (a) {
	return {$: 'BadStatus', a: a};
};
var $elm$http$Http$BadUrl = function (a) {
	return {$: 'BadUrl', a: a};
};
var $elm$http$Http$NetworkError = {$: 'NetworkError'};
var $elm$http$Http$Timeout = {$: 'Timeout'};
var $elm$http$Http$resolve = F2(
	function (toResult, response) {
		switch (response.$) {
			case 'BadUrl_':
				var url = response.a;
				return $elm$core$Result$Err(
					$elm$http$Http$BadUrl(url));
			case 'Timeout_':
				return $elm$core$Result$Err($elm$http$Http$Timeout);
			case 'NetworkError_':
				return $elm$core$Result$Err($elm$http$Http$NetworkError);
			case 'BadStatus_':
				var metadata = response.a;
				return $elm$core$Result$Err(
					$elm$http$Http$BadStatus(metadata.statusCode));
			default:
				var body = response.b;
				return A2(
					$elm$core$Result$mapError,
					$elm$http$Http$BadBody,
					toResult(body));
		}
	});
var $elm$http$Http$expectJson = F2(
	function (toMsg, decoder) {
		return A2(
			$elm$http$Http$expectStringResponse,
			toMsg,
			$elm$http$Http$resolve(
				function (string) {
					return A2(
						$elm$core$Result$mapError,
						$elm$json$Json$Decode$errorToString,
						A2($elm$json$Json$Decode$decodeString, decoder, string));
				}));
	});
var $elm$http$Http$Request = function (a) {
	return {$: 'Request', a: a};
};
var $elm$http$Http$State = F2(
	function (reqs, subs) {
		return {reqs: reqs, subs: subs};
	});
var $elm$http$Http$init = $elm$core$Task$succeed(
	A2($elm$http$Http$State, $elm$core$Dict$empty, _List_Nil));
var $elm$http$Http$updateReqs = F3(
	function (router, cmds, reqs) {
		updateReqs:
		while (true) {
			if (!cmds.b) {
				return $elm$core$Task$succeed(reqs);
			} else {
				var cmd = cmds.a;
				var otherCmds = cmds.b;
				if (cmd.$ === 'Cancel') {
					var tracker = cmd.a;
					var _v2 = A2($elm$core$Dict$get, tracker, reqs);
					if (_v2.$ === 'Nothing') {
						var $temp$router = router,
							$temp$cmds = otherCmds,
							$temp$reqs = reqs;
						router = $temp$router;
						cmds = $temp$cmds;
						reqs = $temp$reqs;
						continue updateReqs;
					} else {
						var pid = _v2.a;
						return A2(
							$elm$core$Task$andThen,
							function (_v3) {
								return A3(
									$elm$http$Http$updateReqs,
									router,
									otherCmds,
									A2($elm$core$Dict$remove, tracker, reqs));
							},
							$elm$core$Process$kill(pid));
					}
				} else {
					var req = cmd.a;
					return A2(
						$elm$core$Task$andThen,
						function (pid) {
							var _v4 = req.tracker;
							if (_v4.$ === 'Nothing') {
								return A3($elm$http$Http$updateReqs, router, otherCmds, reqs);
							} else {
								var tracker = _v4.a;
								return A3(
									$elm$http$Http$updateReqs,
									router,
									otherCmds,
									A3($elm$core$Dict$insert, tracker, pid, reqs));
							}
						},
						$elm$core$Process$spawn(
							A3(
								_Http_toTask,
								router,
								$elm$core$Platform$sendToApp(router),
								req)));
				}
			}
		}
	});
var $elm$http$Http$onEffects = F4(
	function (router, cmds, subs, state) {
		return A2(
			$elm$core$Task$andThen,
			function (reqs) {
				return $elm$core$Task$succeed(
					A2($elm$http$Http$State, reqs, subs));
			},
			A3($elm$http$Http$updateReqs, router, cmds, state.reqs));
	});
var $elm$http$Http$maybeSend = F4(
	function (router, desiredTracker, progress, _v0) {
		var actualTracker = _v0.a;
		var toMsg = _v0.b;
		return _Utils_eq(desiredTracker, actualTracker) ? $elm$core$Maybe$Just(
			A2(
				$elm$core$Platform$sendToApp,
				router,
				toMsg(progress))) : $elm$core$Maybe$Nothing;
	});
var $elm$http$Http$onSelfMsg = F3(
	function (router, _v0, state) {
		var tracker = _v0.a;
		var progress = _v0.b;
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$filterMap,
					A3($elm$http$Http$maybeSend, router, tracker, progress),
					state.subs)));
	});
var $elm$http$Http$Cancel = function (a) {
	return {$: 'Cancel', a: a};
};
var $elm$http$Http$cmdMap = F2(
	function (func, cmd) {
		if (cmd.$ === 'Cancel') {
			var tracker = cmd.a;
			return $elm$http$Http$Cancel(tracker);
		} else {
			var r = cmd.a;
			return $elm$http$Http$Request(
				{
					allowCookiesFromOtherDomains: r.allowCookiesFromOtherDomains,
					body: r.body,
					expect: A2(_Http_mapExpect, func, r.expect),
					headers: r.headers,
					method: r.method,
					timeout: r.timeout,
					tracker: r.tracker,
					url: r.url
				});
		}
	});
var $elm$http$Http$MySub = F2(
	function (a, b) {
		return {$: 'MySub', a: a, b: b};
	});
var $elm$http$Http$subMap = F2(
	function (func, _v0) {
		var tracker = _v0.a;
		var toMsg = _v0.b;
		return A2(
			$elm$http$Http$MySub,
			tracker,
			A2($elm$core$Basics$composeR, toMsg, func));
	});
_Platform_effectManagers['Http'] = _Platform_createManager($elm$http$Http$init, $elm$http$Http$onEffects, $elm$http$Http$onSelfMsg, $elm$http$Http$cmdMap, $elm$http$Http$subMap);
var $elm$http$Http$command = _Platform_leaf('Http');
var $elm$http$Http$subscription = _Platform_leaf('Http');
var $elm$http$Http$request = function (r) {
	return $elm$http$Http$command(
		$elm$http$Http$Request(
			{allowCookiesFromOtherDomains: false, body: r.body, expect: r.expect, headers: r.headers, method: r.method, timeout: r.timeout, tracker: r.tracker, url: r.url}));
};
var $author$project$Traveller$sendRegionRequest = F2(
	function (requestEntry, hostConfig) {
		var regionsDecoder = $miniBill$elm_codec$Codec$decoder(
			$miniBill$elm_codec$Codec$list($author$project$Traveller$Region$codec));
		var _v0 = hostConfig;
		var urlHostRoot = _v0.a;
		var urlHostPath = _v0.b;
		var url = A3(
			$elm$url$Url$Builder$crossOrigin,
			urlHostRoot,
			_Utils_ap(
				urlHostPath,
				_List_fromArray(
					['regions'])),
			_List_Nil);
		var requestCmd = $elm$http$Http$request(
			{
				body: $elm$http$Http$emptyBody,
				expect: A2(
					$elm$http$Http$expectJson,
					$author$project$Traveller$DownloadedRegions(
						_Utils_Tuple2(requestEntry, url)),
					regionsDecoder),
				headers: _List_Nil,
				method: 'GET',
				timeout: $elm$core$Maybe$Just(15000),
				tracker: $elm$core$Maybe$Nothing,
				url: url
			});
		return requestCmd;
	});
var $author$project$Traveller$DownloadedRoute = F2(
	function (a, b) {
		return {$: 'DownloadedRoute', a: a, b: b};
	});
var $author$project$Traveller$Route$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'arrive_day',
		function ($) {
			return $.day;
		},
		$miniBill$elm_codec$Codec$int,
		A4(
			$miniBill$elm_codec$Codec$field,
			'arrive_year',
			function ($) {
				return $.year;
			},
			$miniBill$elm_codec$Codec$int,
			A4(
				$miniBill$elm_codec$Codec$field,
				'ship_id',
				function ($) {
					return $.shipId;
				},
				$miniBill$elm_codec$Codec$int,
				A4(
					$miniBill$elm_codec$Codec$field,
					'to_y',
					A2(
						$elm$core$Basics$composeR,
						function ($) {
							return $.address;
						},
						function ($) {
							return $.y;
						}),
					$miniBill$elm_codec$Codec$int,
					A4(
						$miniBill$elm_codec$Codec$field,
						'to_x',
						A2(
							$elm$core$Basics$composeR,
							function ($) {
								return $.address;
							},
							function ($) {
								return $.x;
							}),
						$miniBill$elm_codec$Codec$int,
						$miniBill$elm_codec$Codec$object(
							F5(
								function (toX, toY, shipId, arriveYear, arriveDay) {
									return {
										address: {x: toX, y: toY},
										day: arriveDay,
										shipId: shipId,
										year: arriveYear
									};
								}))))))));
var $author$project$Traveller$sendRouteRequest = F2(
	function (requestEntry, hostConfig) {
		var routeDecoder = $miniBill$elm_codec$Codec$decoder(
			$miniBill$elm_codec$Codec$list($author$project$Traveller$Route$codec));
		var _v0 = hostConfig;
		var urlHostRoot = _v0.a;
		var urlHostPath = _v0.b;
		var url = A3(
			$elm$url$Url$Builder$crossOrigin,
			urlHostRoot,
			_Utils_ap(
				urlHostPath,
				_List_fromArray(
					['jumps'])),
			_List_Nil);
		var requestCmd = $elm$http$Http$request(
			{
				body: $elm$http$Http$emptyBody,
				expect: A2(
					$elm$http$Http$expectJson,
					$author$project$Traveller$DownloadedRoute(
						_Utils_Tuple2(requestEntry, url)),
					routeDecoder),
				headers: _List_Nil,
				method: 'GET',
				timeout: $elm$core$Maybe$Just(15000),
				tracker: $elm$core$Maybe$Nothing,
				url: url
			});
		return requestCmd;
	});
var $author$project$Traveller$DownloadedSectors = F2(
	function (a, b) {
		return {$: 'DownloadedSectors', a: a, b: b};
	});
var $author$project$Traveller$Sector$Sector = F4(
	function (x, y, name, abbreviation) {
		return {abbreviation: abbreviation, name: name, x: x, y: y};
	});
var $author$project$Traveller$Sector$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'name',
		function ($) {
			return $.abbreviation;
		},
		$miniBill$elm_codec$Codec$string,
		A4(
			$miniBill$elm_codec$Codec$field,
			'name',
			function ($) {
				return $.name;
			},
			$miniBill$elm_codec$Codec$string,
			A4(
				$miniBill$elm_codec$Codec$field,
				'y',
				function ($) {
					return $.y;
				},
				$miniBill$elm_codec$Codec$int,
				A4(
					$miniBill$elm_codec$Codec$field,
					'x',
					function ($) {
						return $.x;
					},
					$miniBill$elm_codec$Codec$int,
					$miniBill$elm_codec$Codec$object($author$project$Traveller$Sector$Sector))))));
var $author$project$Traveller$sendSectorRequest = F2(
	function (requestEntry, hostConfig) {
		var sectorDecoder = $miniBill$elm_codec$Codec$decoder(
			$miniBill$elm_codec$Codec$list($author$project$Traveller$Sector$codec));
		var _v0 = hostConfig;
		var urlHostRoot = _v0.a;
		var urlHostPath = _v0.b;
		var url = A3(
			$elm$url$Url$Builder$crossOrigin,
			urlHostRoot,
			_Utils_ap(
				urlHostPath,
				_List_fromArray(
					['sectors'])),
			_List_Nil);
		var requestCmd = $elm$http$Http$request(
			{
				body: $elm$http$Http$emptyBody,
				expect: A2(
					$elm$http$Http$expectJson,
					$author$project$Traveller$DownloadedSectors(
						_Utils_Tuple2(requestEntry, url)),
					sectorDecoder),
				headers: _List_Nil,
				method: 'GET',
				timeout: $elm$core$Maybe$Just(15000),
				tracker: $elm$core$Maybe$Nothing,
				url: url
			});
		return requestCmd;
	});
var $author$project$Traveller$DownloadedSolarSystems = F2(
	function (a, b) {
		return {$: 'DownloadedSolarSystems', a: a, b: b};
	});
var $author$project$Traveller$SolarSystemStars$FallibleStarSystem = function (address) {
	return function (sectorName) {
		return function (name) {
			return function (scanPoints) {
				return function (surveyIndex) {
					return function (gasGiantCount) {
						return function (terrestrialPlanetCount) {
							return function (planetoidBeltCount) {
								return function (allegiance) {
									return function (nativeSophont) {
										return function (extinctSophont) {
											return function (techLevel) {
												return function (stars) {
													return {address: address, allegiance: allegiance, extinctSophont: extinctSophont, gasGiantCount: gasGiantCount, name: name, nativeSophont: nativeSophont, planetoidBeltCount: planetoidBeltCount, scanPoints: scanPoints, sectorName: sectorName, stars: stars, surveyIndex: surveyIndex, techLevel: techLevel, terrestrialPlanetCount: terrestrialPlanetCount};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $elm$json$Json$Decode$nullable = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder)
			]));
};
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom = $elm$json$Json$Decode$map2($elm$core$Basics$apR);
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required = F3(
	function (key, valDecoder, decoder) {
		return A2(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom,
			A2($elm$json$Json$Decode$field, key, valDecoder),
			decoder);
	});
var $author$project$Traveller$SolarSystemStars$StarTypeData = F7(
	function (au, subtype, companion, stellarType, stellarClass, colour, diameter) {
		return {au: au, colour: colour, companion: companion, diameter: diameter, stellarClass: stellarClass, stellarType: stellarType, subtype: subtype};
	});
var $author$project$Traveller$SolarSystemStars$StarTypeWrap = function (a) {
	return {$: 'StarTypeWrap', a: a};
};
var $author$project$Traveller$StarColour$Blue = {$: 'Blue'};
var $author$project$Traveller$StarColour$BlueWhite = {$: 'BlueWhite'};
var $author$project$Traveller$StarColour$Brown = {$: 'Brown'};
var $author$project$Traveller$StarColour$DeepDimRed = {$: 'DeepDimRed'};
var $author$project$Traveller$StarColour$LightOrange = {$: 'LightOrange'};
var $author$project$Traveller$StarColour$OrangeRed = {$: 'OrangeRed'};
var $author$project$Traveller$StarColour$Red = {$: 'Red'};
var $author$project$Traveller$StarColour$White = {$: 'White'};
var $author$project$Traveller$StarColour$Yellow = {$: 'Yellow'};
var $author$project$Traveller$StarColour$YellowWhite = {$: 'YellowWhite'};
var $miniBill$elm_codec$Codec$enum = F2(
	function (_v0, options) {
		var codec = _v0.a;
		var enc = F2(
			function (queue, val) {
				enc:
				while (true) {
					if (!queue.b) {
						return $elm$json$Json$Encode$null;
					} else {
						var _v2 = queue.a;
						var k = _v2.a;
						var v = _v2.b;
						var tail = queue.b;
						if (_Utils_eq(v, val)) {
							return codec.encoder(k);
						} else {
							var $temp$queue = tail,
								$temp$val = val;
							queue = $temp$queue;
							val = $temp$val;
							continue enc;
						}
					}
				}
			});
		var dec = F2(
			function (queue, key) {
				dec:
				while (true) {
					if (!queue.b) {
						return $elm$json$Json$Decode$fail('Key not found');
					} else {
						var _v4 = queue.a;
						var k = _v4.a;
						var v = _v4.b;
						var tail = queue.b;
						if (_Utils_eq(k, key)) {
							return $elm$json$Json$Decode$succeed(v);
						} else {
							var $temp$queue = tail,
								$temp$key = key;
							queue = $temp$queue;
							key = $temp$key;
							continue dec;
						}
					}
				}
			});
		return $miniBill$elm_codec$Codec$Codec(
			{
				decoder: A2(
					$elm$json$Json$Decode$andThen,
					function (k) {
						return A2(dec, options, k);
					},
					codec.decoder),
				encoder: enc(options)
			});
	});
var $author$project$Traveller$StarColour$codecStarColour = A2(
	$miniBill$elm_codec$Codec$enum,
	$miniBill$elm_codec$Codec$string,
	_List_fromArray(
		[
			_Utils_Tuple2('Blue', $author$project$Traveller$StarColour$Blue),
			_Utils_Tuple2('Blue White', $author$project$Traveller$StarColour$BlueWhite),
			_Utils_Tuple2('White', $author$project$Traveller$StarColour$White),
			_Utils_Tuple2('Yellow White', $author$project$Traveller$StarColour$YellowWhite),
			_Utils_Tuple2('Yellow', $author$project$Traveller$StarColour$Yellow),
			_Utils_Tuple2('Light Orange', $author$project$Traveller$StarColour$LightOrange),
			_Utils_Tuple2('Orange Red', $author$project$Traveller$StarColour$OrangeRed),
			_Utils_Tuple2('Red', $author$project$Traveller$StarColour$Red),
			_Utils_Tuple2('Brown', $author$project$Traveller$StarColour$Brown),
			_Utils_Tuple2('Deep Dim Red', $author$project$Traveller$StarColour$DeepDimRed)
		]));
var $elm$json$Json$Encode$float = _Json_wrap;
var $miniBill$elm_codec$Codec$float = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$float, $elm$json$Json$Decode$float);
var $elm$json$Json$Decode$lazy = function (thunk) {
	return A2(
		$elm$json$Json$Decode$andThen,
		thunk,
		$elm$json$Json$Decode$succeed(_Utils_Tuple0));
};
var $miniBill$elm_codec$Codec$lazy = function (f) {
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: $elm$json$Json$Decode$lazy(
				function (_v0) {
					return $miniBill$elm_codec$Codec$decoder(
						f(_Utils_Tuple0));
				}),
			encoder: function (v) {
				return A2(
					$miniBill$elm_codec$Codec$encoder,
					f(_Utils_Tuple0),
					v);
			}
		});
};
var $miniBill$elm_codec$Codec$map = F3(
	function (go, back, codec) {
		return $miniBill$elm_codec$Codec$Codec(
			{
				decoder: A2(
					$elm$json$Json$Decode$map,
					go,
					$miniBill$elm_codec$Codec$decoder(codec)),
				encoder: function (v) {
					return A2(
						$miniBill$elm_codec$Codec$encoder,
						codec,
						back(v));
				}
			});
	});
var $miniBill$elm_codec$Codec$nullable = function (codec) {
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: $elm$json$Json$Decode$nullable(
				$miniBill$elm_codec$Codec$decoder(codec)),
			encoder: function (v) {
				if (v.$ === 'Nothing') {
					return $elm$json$Json$Encode$null;
				} else {
					var x = v.a;
					return A2($miniBill$elm_codec$Codec$encoder, codec, x);
				}
			}
		});
};
function $author$project$Traveller$SolarSystemStars$cyclic$starTypeCodec() {
	return A3(
		$miniBill$elm_codec$Codec$map,
		$author$project$Traveller$SolarSystemStars$StarTypeWrap,
		function (_v1) {
			var data = _v1.a;
			return data;
		},
		$miniBill$elm_codec$Codec$buildObject(
			A4(
				$miniBill$elm_codec$Codec$field,
				'diameter',
				function ($) {
					return $.diameter;
				},
				$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$float),
				A4(
					$miniBill$elm_codec$Codec$field,
					'colour',
					function ($) {
						return $.colour;
					},
					$miniBill$elm_codec$Codec$nullable($author$project$Traveller$StarColour$codecStarColour),
					A4(
						$miniBill$elm_codec$Codec$field,
						'stellar_class',
						function ($) {
							return $.stellarClass;
						},
						$miniBill$elm_codec$Codec$string,
						A4(
							$miniBill$elm_codec$Codec$field,
							'stellar_type',
							function ($) {
								return $.stellarType;
							},
							$miniBill$elm_codec$Codec$string,
							A4(
								$miniBill$elm_codec$Codec$field,
								'companion',
								function ($) {
									return $.companion;
								},
								$miniBill$elm_codec$Codec$nullable(
									$miniBill$elm_codec$Codec$lazy(
										function (_v0) {
											return $author$project$Traveller$SolarSystemStars$cyclic$starTypeCodec();
										})),
								A4(
									$miniBill$elm_codec$Codec$field,
									'stellar_subtype',
									function ($) {
										return $.subtype;
									},
									$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$int),
									A4(
										$miniBill$elm_codec$Codec$field,
										'au',
										function ($) {
											return $.au;
										},
										$miniBill$elm_codec$Codec$float,
										$miniBill$elm_codec$Codec$object($author$project$Traveller$SolarSystemStars$StarTypeData))))))))));
}
try {
	var $author$project$Traveller$SolarSystemStars$starTypeCodec = $author$project$Traveller$SolarSystemStars$cyclic$starTypeCodec();
	$author$project$Traveller$SolarSystemStars$cyclic$starTypeCodec = function () {
		return $author$project$Traveller$SolarSystemStars$starTypeCodec;
	};
} catch ($) {
	throw 'Some top-level definitions from `Traveller.SolarSystemStars` are causing infinite recursion:\n\n  ┌─────┐\n  │    starTypeCodec\n  └─────┘\n\nThese errors are very tricky, so read https://elm-lang.org/0.19.1/bad-recursion to learn how to fix it!';}
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Traveller$SolarSystemStars$fallibleStarSystemDecoder = function () {
	var decodeOrCatchError = $elm$json$Json$Decode$decodeValue(
		$miniBill$elm_codec$Codec$decoder($author$project$Traveller$SolarSystemStars$starTypeCodec));
	return A3(
		$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
		'stars',
		$elm$json$Json$Decode$list(
			A2($elm$json$Json$Decode$map, decodeOrCatchError, $elm$json$Json$Decode$value)),
		A3(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
			'tech_level',
			$elm$json$Json$Decode$nullable($elm$json$Json$Decode$int),
			A3(
				$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
				'extinct_sophont',
				$elm$json$Json$Decode$bool,
				A3(
					$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
					'native_sophont',
					$elm$json$Json$Decode$bool,
					A3(
						$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
						'allegiance',
						$elm$json$Json$Decode$nullable($elm$json$Json$Decode$string),
						A3(
							$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
							'belt_count',
							$elm$json$Json$Decode$int,
							A3(
								$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
								'terrestrial_count',
								$elm$json$Json$Decode$int,
								A3(
									$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
									'gas_giant_count',
									$elm$json$Json$Decode$int,
									A3(
										$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
										'survey_index',
										$elm$json$Json$Decode$int,
										A3(
											$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
											'scan_points',
											$elm$json$Json$Decode$int,
											A3(
												$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
												'name',
												$elm$json$Json$Decode$string,
												A3(
													$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
													'sector_name',
													$elm$json$Json$Decode$string,
													A3(
														$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
														'origin_y',
														$elm$json$Json$Decode$int,
														A3(
															$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
															'origin_x',
															$elm$json$Json$Decode$int,
															$elm$json$Json$Decode$succeed(
																function (ox) {
																	return function (oy) {
																		return function (sname) {
																			return function (name) {
																				return function (sp) {
																					return function (si) {
																						return function (ggc) {
																							return function (tpc) {
																								return function (ppc) {
																									return function (al) {
																										return function (stars) {
																											return $author$project$Traveller$SolarSystemStars$FallibleStarSystem(
																												{x: ox, y: oy})(sname)(name)(sp)(si)(ggc)(tpc)(ppc)(al)(stars);
																										};
																									};
																								};
																							};
																						};
																					};
																				};
																			};
																		};
																	};
																})))))))))))))));
}();
var $elm$url$Url$Builder$QueryParameter = F2(
	function (a, b) {
		return {$: 'QueryParameter', a: a, b: b};
	});
var $elm$url$Url$percentEncode = _Url_percentEncode;
var $elm$url$Url$Builder$int = F2(
	function (key, value) {
		return A2(
			$elm$url$Url$Builder$QueryParameter,
			$elm$url$Url$percentEncode(key),
			$elm$core$String$fromInt(value));
	});
var $author$project$Traveller$sendSolarSystemRequest = F3(
	function (requestEntry, hostConfig, _v0) {
		var upperLeftHex = _v0.upperLeftHex;
		var lowerRightHex = _v0.lowerRightHex;
		var solarSystemsDecoder = $elm$json$Json$Decode$list($author$project$Traveller$SolarSystemStars$fallibleStarSystemDecoder);
		var _v1 = hostConfig;
		var urlHostRoot = _v1.a;
		var urlHostPath = _v1.b;
		var url = A3(
			$elm$url$Url$Builder$crossOrigin,
			urlHostRoot,
			_Utils_ap(
				urlHostPath,
				_List_fromArray(
					['stars'])),
			_List_fromArray(
				[
					A2($elm$url$Url$Builder$int, 'ulx', upperLeftHex.x),
					A2($elm$url$Url$Builder$int, 'uly', upperLeftHex.y),
					A2($elm$url$Url$Builder$int, 'lrx', lowerRightHex.x),
					A2($elm$url$Url$Builder$int, 'lry', lowerRightHex.y)
				]));
		var requestCmd = $elm$http$Http$request(
			{
				body: $elm$http$Http$emptyBody,
				expect: A2(
					$elm$http$Http$expectJson,
					$author$project$Traveller$DownloadedSolarSystems(
						_Utils_Tuple2(requestEntry, url)),
					solarSystemsDecoder),
				headers: _List_Nil,
				method: 'GET',
				timeout: $elm$core$Maybe$Just(15000),
				tracker: $elm$core$Maybe$Nothing,
				url: url
			});
		return requestCmd;
	});
var $author$project$Traveller$HexAddress$shiftAddressBy = F2(
	function (_v0, hexAddress) {
		var deltaX = _v0.deltaX;
		var deltaY = _v0.deltaY;
		return {x: hexAddress.x + deltaX, y: hexAddress.y - deltaY};
	});
var $author$project$Traveller$HexAddress$universalHexX = function (hexAddr) {
	return hexAddr.x + (hexAddr.sectorX * 32);
};
var $author$project$Traveller$HexAddress$universalHexY = function (hexAddr) {
	return (hexAddr.sectorY * 40) - hexAddr.y;
};
var $author$project$Traveller$HexAddress$toUniversalAddress = function (sectorHex) {
	return {
		x: $author$project$Traveller$HexAddress$universalHexX(sectorHex),
		y: $author$project$Traveller$HexAddress$universalHexY(sectorHex)
	};
};
var $author$project$Traveller$init = F5(
	function (viewport, settings, key, hostConfig, referee) {
		var journeyModel = {
			dragMode: $author$project$Traveller$NoDragging,
			hoverPoint: $elm$core$Maybe$Nothing,
			zoomOffset: _Utils_Tuple2(0, 0),
			zoomScale: 1.0
		};
		var hexRect = function () {
			var upperLeftHex = function () {
				var _v9 = settings.upperLeft;
				if (_v9.$ === 'Just') {
					var _v10 = _v9.a;
					var x = _v10.a;
					var y = _v10.b;
					return A2($author$project$Traveller$HexAddress$HexAddress, x, y);
				} else {
					return $author$project$Traveller$HexAddress$toUniversalAddress(
						{sectorX: -10, sectorY: -2, x: 21, y: 12});
				}
			}();
			var lowerRightHex = A2(
				$author$project$Traveller$HexAddress$shiftAddressBy,
				{deltaX: $author$project$Traveller$defaultHexRectSize, deltaY: $author$project$Traveller$defaultHexRectSize},
				upperLeftHex);
			return {lowerRightHex: lowerRightHex, upperLeftHex: upperLeftHex};
		}();
		var _v0 = _Utils_Tuple2($elm$core$Dict$empty, _List_Nil);
		var initSystemDict = _v0.a;
		var initRequestHistory = _v0.b;
		var _v1 = function (_v6) {
			var _v7 = _v6.a;
			var ssReqEntry_ = _v7.a;
			var secReqEntry_ = _v7.b;
			var oldSsDictAndReqHistory = _v6.b;
			var _v8 = A2($author$project$Traveller$prepNextRequest, oldSsDictAndReqHistory, hexRect);
			var routeReqEntry_ = _v8.a;
			var ssDictAndReqHistory = _v8.b;
			return _Utils_Tuple2(
				_Utils_Tuple3(ssReqEntry_, secReqEntry_, routeReqEntry_),
				ssDictAndReqHistory);
		}(
			function (_v4) {
				var ssReqEntry_ = _v4.a;
				var oldSsDictAndReqHistory = _v4.b;
				var _v5 = A2($author$project$Traveller$prepNextRequest, oldSsDictAndReqHistory, hexRect);
				var newReqEntry = _v5.a;
				var ssDictAndReqHistory = _v5.b;
				return _Utils_Tuple2(
					_Utils_Tuple2(ssReqEntry_, newReqEntry),
					ssDictAndReqHistory);
			}(
				A2(
					$author$project$Traveller$prepNextRequest,
					_Utils_Tuple2(initSystemDict, initRequestHistory),
					hexRect)));
		var _v2 = _v1.a;
		var ssReqEntry = _v2.a;
		var secReqEntry = _v2.b;
		var routeReqEntry = _v2.c;
		var _v3 = _v1.b;
		var solarSystemDict = _v3.a;
		var requestHistory = _v3.b;
		var model = {
			campaignName: A2($elm$core$Maybe$withDefault, 'Navigation', settings.campaignName),
			currentAddress: $author$project$Traveller$HexAddress$toUniversalAddress(
				{sectorX: -10, sectorY: -2, x: 31, y: 24}),
			dragMode: $author$project$Traveller$NoDragging,
			hexColours: $elm$core$Dict$empty,
			hexRect: hexRect,
			hexScale: settings.hexSize,
			hostConfig: hostConfig,
			hoveringHex: $elm$core$Maybe$Nothing,
			isReferee: referee,
			journeyModel: journeyModel,
			key: key,
			lastSolarSystemError: $elm$core$Maybe$Nothing,
			newSolarSystemErrors: _List_Nil,
			objectToBeAnalyzed: $elm$core$Maybe$Nothing,
			oldSolarSystemErrors: _List_Nil,
			rawHexaPoints: $author$project$Traveller$HexGeometry$rawHexagonPoints(settings.hexSize),
			regionLabels: $elm$core$Dict$empty,
			regions: $elm$core$Dict$empty,
			requestHistory: requestHistory,
			route: _List_Nil,
			sectors: $elm$core$Dict$empty,
			selectedHex: $elm$core$Maybe$Nothing,
			selectedStellarObject: $elm$core$Maybe$Nothing,
			selectedSystem: $elm$core$Maybe$Nothing,
			shipName: A2($elm$core$Maybe$withDefault, 'Ship', settings.shipName),
			sidebarHoverText: $elm$core$Maybe$Nothing,
			solarSystems: solarSystemDict,
			timeOpened: $elm$time$Time$millisToPosix(0),
			viewMode: $author$project$Traveller$HexMap,
			viewport: {hexmapViewport: $elm$core$Maybe$Nothing, viewport: viewport}
		};
		return _Utils_Tuple2(
			_Utils_Tuple2(
				$elm$time$Time$millisToPosix(0),
				model),
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[
						A3($author$project$Traveller$sendSolarSystemRequest, ssReqEntry, model.hostConfig, model.hexRect),
						A2($author$project$Traveller$sendSectorRequest, secReqEntry, model.hostConfig),
						A2($author$project$Traveller$sendRegionRequest, secReqEntry, model.hostConfig),
						A2($author$project$Traveller$sendRouteRequest, routeReqEntry, model.hostConfig)
					])));
	});
var $elm$browser$Browser$Navigation$load = _Browser_load;
var $elm$core$Platform$Cmd$map = _Platform_map;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $elm$browser$Browser$Navigation$pushUrl = _Browser_pushUrl;
var $elm$url$Url$addPort = F2(
	function (maybePort, starter) {
		if (maybePort.$ === 'Nothing') {
			return starter;
		} else {
			var port_ = maybePort.a;
			return starter + (':' + $elm$core$String$fromInt(port_));
		}
	});
var $elm$url$Url$addPrefixed = F3(
	function (prefix, maybeSegment, starter) {
		if (maybeSegment.$ === 'Nothing') {
			return starter;
		} else {
			var segment = maybeSegment.a;
			return _Utils_ap(
				starter,
				_Utils_ap(prefix, segment));
		}
	});
var $elm$url$Url$toString = function (url) {
	var http = function () {
		var _v0 = url.protocol;
		if (_v0.$ === 'Http') {
			return 'http://';
		} else {
			return 'https://';
		}
	}();
	return A3(
		$elm$url$Url$addPrefixed,
		'#',
		url.fragment,
		A3(
			$elm$url$Url$addPrefixed,
			'?',
			url.query,
			_Utils_ap(
				A2(
					$elm$url$Url$addPort,
					url.port_,
					_Utils_ap(http, url.host)),
				url.path)));
};
var $author$project$Main$toggleDialog = _Platform_outgoingPort('toggleDialog', $elm$json$Json$Encode$string);
var $author$project$Traveller$AnalysisDetail$AnalyisDetailGasGiant = F2(
	function (a, b) {
		return {$: 'AnalyisDetailGasGiant', a: a, b: b};
	});
var $author$project$Traveller$AnalysisDetail$AnalyisDetailPlanetoid = F2(
	function (a, b) {
		return {$: 'AnalyisDetailPlanetoid', a: a, b: b};
	});
var $author$project$Traveller$AnalysisDetail$AnalyisDetailPlanetoidBelt = F2(
	function (a, b) {
		return {$: 'AnalyisDetailPlanetoidBelt', a: a, b: b};
	});
var $author$project$Traveller$AnalysisDetail$AnalyisDetailStar = {$: 'AnalyisDetailStar'};
var $author$project$Traveller$DownloadSolarSystems = {$: 'DownloadSolarSystems'};
var $cuducos$elm_format_number$FormatNumber$Locales$Exact = function (a) {
	return {$: 'Exact', a: a};
};
var $author$project$Traveller$FailedSolarSystem = function (a) {
	return {$: 'FailedSolarSystem', a: a};
};
var $author$project$Traveller$FailedStarsSolarSystem = function (a) {
	return {$: 'FailedStarsSolarSystem', a: a};
};
var $krisajenkins$remotedata$RemoteData$Failure = function (a) {
	return {$: 'Failure', a: a};
};
var $author$project$Traveller$FullJourney = {$: 'FullJourney'};
var $author$project$Traveller$GotHexMapViewport = function (a) {
	return {$: 'GotHexMapViewport', a: a};
};
var $author$project$Traveller$IsDragging = function (a) {
	return {$: 'IsDragging', a: a};
};
var $author$project$Traveller$LoadedEmptyHex = {$: 'LoadedEmptyHex'};
var $author$project$Traveller$LoadedSolarSystem = function (a) {
	return {$: 'LoadedSolarSystem', a: a};
};
var $author$project$Traveller$OpenedObjectAnalysisTime = function (a) {
	return {$: 'OpenedObjectAnalysisTime', a: a};
};
var $krisajenkins$remotedata$RemoteData$Success = function (a) {
	return {$: 'Success', a: a};
};
var $author$project$Traveller$ZoomToHex = F2(
	function (a, b) {
		return {$: 'ZoomToHex', a: a, b: b};
	});
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $author$project$Traveller$Atmosphere$atmosphereDescriptionEx = function (code) {
	switch (code) {
		case 0:
			return 'None (Survival Gear: Vacc Suit)';
		case 1:
			return 'Trace (Survival Gear: Vacc Suit)';
		case 2:
			return 'Very Thin, Tainted (Survival Gear: Respirator and Filter)';
		case 3:
			return 'Very Thin (Survival Gear: Respirator)';
		case 4:
			return 'Thin, Tainted (Survival Gear: Filter)';
		case 5:
			return 'Thin (Survival Gear: None)';
		case 6:
			return 'Standard (Survival Gear: None)';
		case 7:
			return 'Standard, Tainted (Survival Gear: Filter)';
		case 8:
			return 'Dense (Survival Gear: None)';
		case 9:
			return 'Dense, Tainted (Survival Gear: Filter)';
		case 10:
			return 'Exotic (Survival Gear: Air Supply)';
		case 11:
			return 'Corrosive (Survival Gear: Vacc Suit)';
		case 12:
			return 'Insidious (Survival Gear: Vacc Suit)';
		case 13:
			return 'Very Dense (Survival Gear: Varies by altitude)';
		case 14:
			return 'Low (Survival Gear: Varies by altitude)';
		case 15:
			return 'Unusual (Survival Gear: Varies)';
		case 16:
			return 'Gas, Helium (Survival Gear: HEV Suit)';
		case 17:
			return 'Gas, Hydrogen (Survival Gear: Not Survivable)';
		default:
			return 'Unknown atmosphere code';
	}
};
var $author$project$Traveller$Atmosphere$atmosphereHazardDescription = function (maybeCode) {
	if (maybeCode.$ === 'Nothing') {
		return 'N/A';
	} else {
		switch (maybeCode.a) {
			case 'B':
				return 'Biologic';
			case 'G':
				return 'Gas Mix';
			case 'R':
				return 'Radioctivity';
			case 'T':
				return 'Temperature';
			default:
				return 'N/A';
		}
	}
};
var $elm$core$Task$onError = _Scheduler_onError;
var $elm$core$Task$attempt = F2(
	function (resultToMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2(
					$elm$core$Task$onError,
					A2(
						$elm$core$Basics$composeL,
						A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
						$elm$core$Result$Err),
					A2(
						$elm$core$Task$andThen,
						A2(
							$elm$core$Basics$composeL,
							A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
							$elm$core$Result$Ok),
						task))));
	});
var $author$project$Traveller$Lifeforms$bioChemistryCompatibilityDescription = function (compatibilityRating) {
	return (compatibilityRating < 10) ? ($elm$core$String$fromInt(compatibilityRating * 10) + '%') : '100% compatible';
};
var $author$project$Traveller$Lifeforms$biocomplexityDescription = function (rating) {
	switch (rating) {
		case 1:
			return 'Primitive single-cell organisms – Procaryotes such as bacteria and archaea.';
		case 2:
			return 'Advanced cellular organisms – Eucaryotes such as algae and amoebae.';
		case 3:
			return 'Primitive multicellular organisms – Lichen, sponges, some fungi.';
		case 4:
			return 'Differentiated multicellular organisms – Ediacaran and early Cambrian age creatures.';
		case 5:
			return 'Complex multicellular organisms – Insects, ferns, fish.';
		case 6:
			return 'Advanced multicellular organisms – Reptiles, birds, mammals, flowering plants.';
		case 7:
			return 'Socially advanced organisms – Ants, bees, primates, elephants.';
		case 8:
			return 'Mentally advanced organisms – Sophont intelligence, psionics.';
		case 9:
			return 'Extant or extinct sophonts – At some point, this world had sophont lifeforms.';
		case 10:
			return 'Ecosystem-wide superorganisms – Cooperative sophont-like behaviour.';
		default:
			return 'Unknown biocomplexity rating.';
	}
};
var $author$project$Traveller$Lifeforms$biodiversityDescription = function (code) {
	switch (code) {
		case 0:
			return 'Sterile – No detectable biomass. Lifeless rock, ice, or gas; may have organics but no living organisms.';
		case 1:
			return 'Trace Life – Microbes or simple extremophiles in niche environments; no visible macroscopic life.';
		case 2:
			return 'Minimal – Simple ecosystems with only a few hardy species; mostly barren terrain with scattered life pockets.';
		case 3:
			return 'Sparse – Low diversity; a small number of dominant species across most environments.';
		case 4:
			return 'Limited – Multiple species present, but ecosystems remain simple and repetitive.';
		case 5:
			return 'Moderate – Distinct ecosystems present, but limited species turnover; a ‘familiar’ set of organisms across large areas.';
		case 6:
			return 'Developing – Several well-defined ecosystems with moderate inter-species complexity; seasonal or regional variety.';
		case 7:
			return 'Rich – Diverse biomes with strong species variety; food webs are complex but not maximal.';
		case 8:
			return 'Very Rich – Highly varied ecosystems with strong regional specialisation; many niches filled.';
		case 9:
			return 'Abundant – Dense, highly interconnected food webs; ecosystems recover quickly from disruption.';
		case 10:
			return 'Terra-Equivalent – Biodiversity equal to pre-human Earth; extremely complex, stable, and resilient biosphere.';
		default:
			return 'Hyperdiverse – More complex than pre-human Earth; alien biochemistries or evolutionary histories have produced extreme species variety.';
	}
};
var $author$project$Traveller$Lifeforms$biomassDescription = function (rating) {
	switch (rating) {
		case 0:
			return 'None (No native life exists; surface and atmosphere sterile)';
		case 1:
			return 'Trace (Microscopic or sparse microbial life, often in isolated niches)';
		case 2:
			return 'Very Low (Thin biosphere, with small colonies of hardy species; biomass barely detectable from orbit)';
		case 3:
			return 'Low (Life present in limited habitats, such as only in oceans, lakes, or certain regions)';
		case 4:
			return 'Moderate-Low (Ecosystems present but not lush; limited vegetation and animal density)';
		case 5:
			return 'Moderate (Noticeable biomass in most regions; productive ecosystems but still thin compared to fertile worlds)';
		case 6:
			return 'Moderate-High (Healthy and varied biomass in most regions; large, stable food webs)';
		case 7:
			return 'High (Dense plant and animal life in most biomes; little uncolonised surface)';
		case 8:
			return 'Very High (Rich biomass with extreme density in some regions; ecosystems highly productive year-round)';
		case 9:
			return 'Abundant (Biomass so high it shapes climate and geology; ecosystems are resilient and self-repairing)';
		case 10:
			return 'Garden World (Equivalent to pre-human Terra; lush, balanced, and productive biosphere across the planet)';
		default:
			return (rating < 0) ? 'None (No native life exists; surface and atmosphere sterile)' : 'Hyper-abundant (More biomass than pre-human Terra; alien biochemistries or evolutionary histories have produced extreme productivity)';
	}
};
var $avh4$elm_color$Color$blue = A4($avh4$elm_color$Color$RgbaSpace, 52 / 255, 101 / 255, 164 / 255, 1.0);
var $elm$core$Basics$clamp = F3(
	function (low, high, number) {
		return (_Utils_cmp(number, low) < 0) ? low : ((_Utils_cmp(number, high) > 0) ? high : number);
	});
var $author$project$Traveller$HexAddress$create = function (_v0) {
	var sectorX = _v0.sectorX;
	var sectorY = _v0.sectorY;
	var x = _v0.x;
	var y = _v0.y;
	return {sectorX: sectorX, sectorY: sectorY, x: x, y: y};
};
var $author$project$Traveller$HexAddress$createFromStarSystem = function (_v0) {
	var sectorX = _v0.sectorX;
	var sectorY = _v0.sectorY;
	var x = _v0.x;
	var y = _v0.y;
	return $author$project$Traveller$HexAddress$toUniversalAddress(
		$author$project$Traveller$HexAddress$create(
			{sectorX: sectorX, sectorY: sectorY, x: x, y: y}));
};
var $author$project$Traveller$FetchedSolarSystem = function (a) {
	return {$: 'FetchedSolarSystem', a: a};
};
var $author$project$Traveller$SolarSystem$finalToRaw = function (solarSystem) {
	return {allegiance: solarSystem.allegiance, extinctSophont: solarSystem.extinctSophont, gasGiants: solarSystem.gasGiants, name: solarSystem.name, nativeSophont: solarSystem.nativeSophont, planetoidBelts: solarSystem.planetoidBelts, primaryStar: solarSystem.primaryStar, sectorName: solarSystem.sectorName, sectorX: 9999999999, sectorY: 9999999999, surveyIndex: solarSystem.surveyIndex, terrestrialPlanets: solarSystem.terrestrialPlanets, x: 9999999999, y: 9999999999};
};
var $author$project$Traveller$SolarSystem$RawSolarSystem = function (x) {
	return function (y) {
		return function (primaryStar) {
			return function (gasGiants) {
				return function (planetoidBelts) {
					return function (terrestrialPlanets) {
						return function (surveyIndex) {
							return function (nativeSophont) {
								return function (extinctSophont) {
									return function (sectorX) {
										return function (sectorY) {
											return function (allegiance) {
												return function (name) {
													return function (sectorName) {
														return {allegiance: allegiance, extinctSophont: extinctSophont, gasGiants: gasGiants, name: name, nativeSophont: nativeSophont, planetoidBelts: planetoidBelts, primaryStar: primaryStar, sectorName: sectorName, sectorX: sectorX, sectorY: sectorY, surveyIndex: surveyIndex, terrestrialPlanets: terrestrialPlanets, x: x, y: y};
													};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $elm$json$Json$Encode$bool = _Json_wrap;
var $miniBill$elm_codec$Codec$bool = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$bool, $elm$json$Json$Decode$bool);
var $author$project$Traveller$StellarObject$GasGiant = function (a) {
	return {$: 'GasGiant', a: a};
};
var $author$project$Traveller$StellarObject$InnerStarData = function (orbitPosition) {
	return function (inclination) {
		return function (eccentricity) {
			return function (effectiveHZCODeviation) {
				return function (stellarClass) {
					return function (stellarType) {
						return function (subtype) {
							return function (orbitType) {
								return function (mass) {
									return function (diameter) {
										return function (temperature) {
											return function (age) {
												return function (colour) {
													return function (companion) {
														return function (orbit) {
															return function (period) {
																return function (baseline) {
																	return function (stellarObjects) {
																		return function (orbitSequence) {
																			return function (safeJumpTime) {
																				return function (au) {
																					return function (jumpShadow) {
																						return {age: age, au: au, baseline: baseline, colour: colour, companion: companion, diameter: diameter, eccentricity: eccentricity, effectiveHZCODeviation: effectiveHZCODeviation, inclination: inclination, jumpShadow: jumpShadow, mass: mass, orbit: orbit, orbitPosition: orbitPosition, orbitSequence: orbitSequence, orbitType: orbitType, period: period, safeJumpTime: safeJumpTime, stellarClass: stellarClass, stellarObjects: stellarObjects, stellarType: stellarType, subtype: subtype, temperature: temperature};
																					};
																				};
																			};
																		};
																	};
																};
															};
														};
													};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $author$project$Traveller$StellarObject$Planetoid = function (a) {
	return {$: 'Planetoid', a: a};
};
var $author$project$Traveller$StellarObject$PlanetoidBelt = function (a) {
	return {$: 'PlanetoidBelt', a: a};
};
var $author$project$Traveller$StellarObject$Star = function (a) {
	return {$: 'Star', a: a};
};
var $author$project$Traveller$StellarObject$StarDataWrap = function (a) {
	return {$: 'StarDataWrap', a: a};
};
var $author$project$Traveller$StellarObject$TerrestrialPlanet = function (a) {
	return {$: 'TerrestrialPlanet', a: a};
};
var $author$project$Traveller$Point$StellarPoint = F2(
	function (x, y) {
		return {x: x, y: y};
	});
var $author$project$Traveller$Point$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'y',
		function ($) {
			return $.y;
		},
		$miniBill$elm_codec$Codec$float,
		A4(
			$miniBill$elm_codec$Codec$field,
			'x',
			function ($) {
				return $.x;
			},
			$miniBill$elm_codec$Codec$float,
			$miniBill$elm_codec$Codec$object($author$project$Traveller$Point$StellarPoint))));
var $author$project$Traveller$Moon$Moon = function (orbitPosition) {
	return function (inclination) {
		return function (eccentricity) {
			return function (effectiveHZCODeviation) {
				return function (orbit) {
					return function (size) {
						return function (period) {
							return function (biomassRating) {
								return function (axialTilt) {
									return function (safeJumpDistance) {
										return {axialTilt: axialTilt, biomassRating: biomassRating, eccentricity: eccentricity, effectiveHZCODeviation: effectiveHZCODeviation, inclination: inclination, orbit: orbit, orbitPosition: orbitPosition, period: period, safeJumpDistance: safeJumpDistance, size: size};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $author$project$Traveller$Orbit$ComplexOrbit = function (a) {
	return {$: 'ComplexOrbit', a: a};
};
var $author$project$Traveller$Orbit$SimpleOrbit = function (a) {
	return {$: 'SimpleOrbit', a: a};
};
var $author$project$Traveller$Orbit$codec = A2(
	$miniBill$elm_codec$Codec$build,
	function (stellarOrbit) {
		if (stellarOrbit.$ === 'SimpleOrbit') {
			var orbit = stellarOrbit.a;
			return $elm$json$Json$Encode$float(orbit);
		} else {
			var complexOrbitData = stellarOrbit.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'zone',
						$elm$json$Json$Encode$string(complexOrbitData.zone)),
						_Utils_Tuple2(
						'orbit',
						function () {
							var _v1 = complexOrbitData.orbit;
							if (_v1.$ === 'Just') {
								var orbitNum = _v1.a;
								return $elm$json$Json$Encode$float(orbitNum);
							} else {
								return $elm$json$Json$Encode$null;
							}
						}())
					]));
		}
	},
	$elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $author$project$Traveller$Orbit$SimpleOrbit, $elm$json$Json$Decode$float),
				A3(
				$elm$json$Json$Decode$map2,
				F2(
					function (zone_, orbit) {
						return $author$project$Traveller$Orbit$ComplexOrbit(
							{orbit: orbit, zone: zone_});
					}),
				A2($elm$json$Json$Decode$field, 'zone', $elm$json$Json$Decode$string),
				A2(
					$elm$json$Json$Decode$field,
					'orbit',
					$elm$json$Json$Decode$nullable($elm$json$Json$Decode$float)))
			])));
var $miniBill$elm_codec$Codec$oneOf = F2(
	function (main, alts) {
		return $miniBill$elm_codec$Codec$Codec(
			{
				decoder: $elm$json$Json$Decode$oneOf(
					A2(
						$elm$core$List$cons,
						$miniBill$elm_codec$Codec$decoder(main),
						A2($elm$core$List$map, $miniBill$elm_codec$Codec$decoder, alts))),
				encoder: $miniBill$elm_codec$Codec$encoder(main)
			});
	});
var $author$project$Traveller$Moon$codecMoonSize = A2(
	$miniBill$elm_codec$Codec$oneOf,
	$miniBill$elm_codec$Codec$string,
	_List_fromArray(
		[
			A3(
			$miniBill$elm_codec$Codec$map,
			$elm$core$String$fromInt,
			A2(
				$elm$core$Basics$composeR,
				$elm$core$String$toInt,
				$elm$core$Maybe$withDefault(0)),
			$miniBill$elm_codec$Codec$int)
		]));
var $elm$json$Json$Decode$keyValuePairs = _Json_decodeKeyValuePairs;
var $miniBill$elm_codec$Codec$optionalField = F4(
	function (name, getter, codec, _v0) {
		var ocodec = _v0.a;
		return $miniBill$elm_codec$Codec$ObjectCodec(
			{
				decoder: A3(
					$elm$json$Json$Decode$map2,
					F2(
						function (f, x) {
							return f(x);
						}),
					ocodec.decoder,
					A2(
						$elm$json$Json$Decode$andThen,
						function (json) {
							return A2(
								$elm$core$List$any,
								function (_v1) {
									var k = _v1.a;
									return _Utils_eq(k, name);
								},
								json) ? A2(
								$elm$json$Json$Decode$map,
								$elm$core$Maybe$Just,
								A2(
									$elm$json$Json$Decode$field,
									name,
									$miniBill$elm_codec$Codec$decoder(codec))) : $elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing);
						},
						$elm$json$Json$Decode$keyValuePairs($elm$json$Json$Decode$value))),
				encoder: function (v) {
					var _v2 = getter(v);
					if (_v2.$ === 'Just') {
						var present = _v2.a;
						return A2(
							$elm$core$List$cons,
							_Utils_Tuple2(
								name,
								A2($miniBill$elm_codec$Codec$encoder, codec, present)),
							ocodec.encoder(v));
					} else {
						return ocodec.encoder(v);
					}
				}
			});
	});
var $miniBill$elm_codec$Codec$optionalNullableField = F4(
	function (name, getter, codec, _v0) {
		var ocodec = _v0.a;
		return $miniBill$elm_codec$Codec$ObjectCodec(
			{
				decoder: A3(
					$elm$json$Json$Decode$map2,
					F2(
						function (f, x) {
							return f(x);
						}),
					ocodec.decoder,
					A2(
						$elm$json$Json$Decode$andThen,
						function (json) {
							return A2(
								$elm$core$List$any,
								function (_v1) {
									var k = _v1.a;
									return _Utils_eq(k, name);
								},
								json) ? A2(
								$elm$json$Json$Decode$field,
								name,
								$elm$json$Json$Decode$nullable(
									$miniBill$elm_codec$Codec$decoder(codec))) : $elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing);
						},
						$elm$json$Json$Decode$keyValuePairs($elm$json$Json$Decode$value))),
				encoder: function (v) {
					var _v2 = getter(v);
					if (_v2.$ === 'Just') {
						var present = _v2.a;
						return A2(
							$elm$core$List$cons,
							_Utils_Tuple2(
								name,
								A2($miniBill$elm_codec$Codec$encoder, codec, present)),
							ocodec.encoder(v));
					} else {
						return ocodec.encoder(v);
					}
				}
			});
	});
var $author$project$Traveller$Moon$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$optionalField,
		'safe_jump_distance',
		function ($) {
			return $.safeJumpDistance;
		},
		$miniBill$elm_codec$Codec$string,
		A4(
			$miniBill$elm_codec$Codec$field,
			'axial_tilt',
			function ($) {
				return $.axialTilt;
			},
			$miniBill$elm_codec$Codec$float,
			A4(
				$miniBill$elm_codec$Codec$field,
				'biomass_rating',
				function ($) {
					return $.biomassRating;
				},
				$miniBill$elm_codec$Codec$int,
				A4(
					$miniBill$elm_codec$Codec$optionalNullableField,
					'period',
					function ($) {
						return $.period;
					},
					$miniBill$elm_codec$Codec$float,
					A4(
						$miniBill$elm_codec$Codec$field,
						'size',
						function ($) {
							return $.size;
						},
						$author$project$Traveller$Moon$codecMoonSize,
						A4(
							$miniBill$elm_codec$Codec$field,
							'orbit',
							function ($) {
								return $.orbit;
							},
							$miniBill$elm_codec$Codec$nullable($author$project$Traveller$Orbit$codec),
							A4(
								$miniBill$elm_codec$Codec$field,
								'effective_hzco_deviation',
								function ($) {
									return $.effectiveHZCODeviation;
								},
								$miniBill$elm_codec$Codec$float,
								A4(
									$miniBill$elm_codec$Codec$field,
									'eccentricity',
									function ($) {
										return $.eccentricity;
									},
									$miniBill$elm_codec$Codec$float,
									A4(
										$miniBill$elm_codec$Codec$field,
										'inclination',
										function ($) {
											return $.inclination;
										},
										$miniBill$elm_codec$Codec$float,
										A4(
											$miniBill$elm_codec$Codec$field,
											'orbit_position',
											function ($) {
												return $.orbitPosition;
											},
											$author$project$Traveller$Point$codec,
											$miniBill$elm_codec$Codec$object($author$project$Traveller$Moon$Moon))))))))))));
var $author$project$Traveller$StellarObject$codecGasGiantData = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'au',
		function ($) {
			return $.au;
		},
		$miniBill$elm_codec$Codec$float,
		A4(
			$miniBill$elm_codec$Codec$field,
			'orbit_type',
			function ($) {
				return $.orbitType;
			},
			$miniBill$elm_codec$Codec$int,
			A4(
				$miniBill$elm_codec$Codec$field,
				'safe_jump_time',
				function ($) {
					return $.safeJumpTime;
				},
				$miniBill$elm_codec$Codec$string,
				A4(
					$miniBill$elm_codec$Codec$field,
					'orbit_sequence',
					function ($) {
						return $.orbitSequence;
					},
					$miniBill$elm_codec$Codec$string,
					A4(
						$miniBill$elm_codec$Codec$field,
						'period',
						function ($) {
							return $.period;
						},
						$miniBill$elm_codec$Codec$float,
						A4(
							$miniBill$elm_codec$Codec$field,
							'axial_tilt',
							function ($) {
								return $.axialTilt;
							},
							$miniBill$elm_codec$Codec$float,
							A4(
								$miniBill$elm_codec$Codec$optionalNullableField,
								'trojan_offset',
								function ($) {
									return $.trojanOffset;
								},
								$miniBill$elm_codec$Codec$float,
								A4(
									$miniBill$elm_codec$Codec$optionalField,
									'has_ring',
									function (d) {
										return $elm$core$Maybe$Just(d.hasRing);
									},
									$miniBill$elm_codec$Codec$bool,
									A4(
										$miniBill$elm_codec$Codec$field,
										'moons',
										function ($) {
											return $.moons;
										},
										A2(
											$miniBill$elm_codec$Codec$build,
											$miniBill$elm_codec$Codec$encoder(
												$miniBill$elm_codec$Codec$list($author$project$Traveller$Moon$codec)),
											$elm$json$Json$Decode$oneOf(
												_List_fromArray(
													[
														$miniBill$elm_codec$Codec$decoder(
														$miniBill$elm_codec$Codec$list($author$project$Traveller$Moon$codec)),
														$elm$json$Json$Decode$succeed(_List_Nil)
													]))),
										A4(
											$miniBill$elm_codec$Codec$field,
											'orbit',
											function ($) {
												return $.orbit;
											},
											$miniBill$elm_codec$Codec$float,
											A4(
												$miniBill$elm_codec$Codec$optionalNullableField,
												'mass',
												function ($) {
													return $.mass;
												},
												$miniBill$elm_codec$Codec$float,
												A4(
													$miniBill$elm_codec$Codec$field,
													'diameter',
													function ($) {
														return $.diameter;
													},
													$miniBill$elm_codec$Codec$float,
													A4(
														$miniBill$elm_codec$Codec$field,
														'code',
														function ($) {
															return $.code;
														},
														$miniBill$elm_codec$Codec$string,
														A4(
															$miniBill$elm_codec$Codec$field,
															'effective_hzco_deviation',
															function ($) {
																return $.effectiveHZCODeviation;
															},
															$miniBill$elm_codec$Codec$float,
															A4(
																$miniBill$elm_codec$Codec$field,
																'eccentricity',
																function ($) {
																	return $.eccentricity;
																},
																$miniBill$elm_codec$Codec$float,
																A4(
																	$miniBill$elm_codec$Codec$field,
																	'inclination',
																	function ($) {
																		return $.inclination;
																	},
																	$miniBill$elm_codec$Codec$float,
																	A4(
																		$miniBill$elm_codec$Codec$field,
																		'orbit_position',
																		function ($) {
																			return $.orbitPosition;
																		},
																		$author$project$Traveller$Point$codec,
																		$miniBill$elm_codec$Codec$object(
																			function (pos) {
																				return function (inc) {
																					return function (ecc) {
																						return function (hzco) {
																							return function (code_) {
																								return function (diam) {
																									return function (mass_) {
																										return function (orb) {
																											return function (mns) {
																												return function (hasRingM) {
																													return function (tj) {
																														return function (axTilt) {
																															return function (per) {
																																return function (orbitSeq) {
																																	return function (sjt) {
																																		return function (ot) {
																																			return function (au) {
																																				return {
																																					au: au,
																																					axialTilt: axTilt,
																																					code: code_,
																																					diameter: diam,
																																					eccentricity: ecc,
																																					effectiveHZCODeviation: hzco,
																																					hasRing: A2($elm$core$Maybe$withDefault, false, hasRingM),
																																					inclination: inc,
																																					mass: mass_,
																																					moons: mns,
																																					orbit: orb,
																																					orbitPosition: pos,
																																					orbitSequence: orbitSeq,
																																					orbitType: ot,
																																					period: per,
																																					safeJumpTime: sjt,
																																					trojanOffset: tj
																																				};
																																			};
																																		};
																																	};
																																};
																															};
																														};
																													};
																												};
																											};
																										};
																									};
																								};
																							};
																						};
																					};
																				};
																			})))))))))))))))))));
var $author$project$Traveller$StellarObject$PlanetoidBeltData = function (orbitPosition) {
	return function (inclination) {
		return function (eccentricity) {
			return function (effectiveHZCODeviation) {
				return function (orbit) {
					return function (mType) {
						return function (sType) {
							return function (cType) {
								return function (oType) {
									return function (span) {
										return function (bulk) {
											return function (resourceRating) {
												return function (period) {
													return function (orbitSequence) {
														return function (uwp) {
															return function (safeJumpTime) {
																return function (orbitType) {
																	return function (au) {
																		return {au: au, bulk: bulk, cType: cType, eccentricity: eccentricity, effectiveHZCODeviation: effectiveHZCODeviation, inclination: inclination, mType: mType, oType: oType, orbit: orbit, orbitPosition: orbitPosition, orbitSequence: orbitSequence, orbitType: orbitType, period: period, resourceRating: resourceRating, sType: sType, safeJumpTime: safeJumpTime, span: span, uwp: uwp};
																	};
																};
															};
														};
													};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $author$project$Traveller$StellarObject$codecPlanetoidBeltData = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'au',
		function ($) {
			return $.au;
		},
		$miniBill$elm_codec$Codec$float,
		A4(
			$miniBill$elm_codec$Codec$field,
			'orbit_type',
			function ($) {
				return $.orbitType;
			},
			$miniBill$elm_codec$Codec$int,
			A4(
				$miniBill$elm_codec$Codec$field,
				'safe_jump_time',
				function ($) {
					return $.safeJumpTime;
				},
				$miniBill$elm_codec$Codec$string,
				A4(
					$miniBill$elm_codec$Codec$field,
					'uwp',
					function ($) {
						return $.uwp;
					},
					$miniBill$elm_codec$Codec$string,
					A4(
						$miniBill$elm_codec$Codec$field,
						'orbit_sequence',
						function ($) {
							return $.orbitSequence;
						},
						$miniBill$elm_codec$Codec$string,
						A4(
							$miniBill$elm_codec$Codec$field,
							'period',
							function ($) {
								return $.period;
							},
							$miniBill$elm_codec$Codec$float,
							A4(
								$miniBill$elm_codec$Codec$field,
								'resource_rating',
								function ($) {
									return $.resourceRating;
								},
								$miniBill$elm_codec$Codec$float,
								A4(
									$miniBill$elm_codec$Codec$field,
									'bulk',
									function ($) {
										return $.bulk;
									},
									$miniBill$elm_codec$Codec$float,
									A4(
										$miniBill$elm_codec$Codec$field,
										'span',
										function ($) {
											return $.span;
										},
										$miniBill$elm_codec$Codec$float,
										A4(
											$miniBill$elm_codec$Codec$field,
											'o_type',
											function ($) {
												return $.oType;
											},
											$miniBill$elm_codec$Codec$float,
											A4(
												$miniBill$elm_codec$Codec$field,
												'c_type',
												function ($) {
													return $.cType;
												},
												$miniBill$elm_codec$Codec$float,
												A4(
													$miniBill$elm_codec$Codec$field,
													's_type',
													function ($) {
														return $.sType;
													},
													$miniBill$elm_codec$Codec$float,
													A4(
														$miniBill$elm_codec$Codec$field,
														'm_type',
														function ($) {
															return $.mType;
														},
														$miniBill$elm_codec$Codec$float,
														A4(
															$miniBill$elm_codec$Codec$field,
															'orbit',
															function ($) {
																return $.orbit;
															},
															$miniBill$elm_codec$Codec$float,
															A4(
																$miniBill$elm_codec$Codec$field,
																'effective_hzco_deviation',
																function ($) {
																	return $.effectiveHZCODeviation;
																},
																$miniBill$elm_codec$Codec$float,
																A4(
																	$miniBill$elm_codec$Codec$field,
																	'eccentricity',
																	function ($) {
																		return $.eccentricity;
																	},
																	$miniBill$elm_codec$Codec$float,
																	A4(
																		$miniBill$elm_codec$Codec$field,
																		'inclination',
																		function ($) {
																			return $.inclination;
																		},
																		$miniBill$elm_codec$Codec$float,
																		A4(
																			$miniBill$elm_codec$Codec$field,
																			'orbit_position',
																			function ($) {
																				return $.orbitPosition;
																			},
																			$author$project$Traveller$Point$codec,
																			$miniBill$elm_codec$Codec$object($author$project$Traveller$StellarObject$PlanetoidBeltData))))))))))))))))))));
var $author$project$Traveller$Atmosphere$StellarAtmosphere = F8(
	function (code, irritant, taint, characteristic, bar, gasType, density, hazardCode) {
		return {bar: bar, characteristic: characteristic, code: code, density: density, gasType: gasType, hazardCode: hazardCode, irritant: irritant, taint: taint};
	});
var $author$project$Traveller$StellarTaint$StellarTaint = F4(
	function (subtype, code, severity, persistence) {
		return {code: code, persistence: persistence, severity: severity, subtype: subtype};
	});
var $author$project$Traveller$StellarTaint$codecStellarTaint = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'persistence',
		function ($) {
			return $.persistence;
		},
		$miniBill$elm_codec$Codec$int,
		A4(
			$miniBill$elm_codec$Codec$field,
			'severity',
			function ($) {
				return $.severity;
			},
			$miniBill$elm_codec$Codec$int,
			A4(
				$miniBill$elm_codec$Codec$field,
				'code',
				function ($) {
					return $.code;
				},
				$miniBill$elm_codec$Codec$string,
				A4(
					$miniBill$elm_codec$Codec$field,
					'subtype',
					function ($) {
						return $.subtype;
					},
					$miniBill$elm_codec$Codec$string,
					$miniBill$elm_codec$Codec$object($author$project$Traveller$StellarTaint$StellarTaint))))));
var $author$project$Traveller$Atmosphere$codec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'hazardCode',
		function ($) {
			return $.hazardCode;
		},
		$miniBill$elm_codec$Codec$maybe($miniBill$elm_codec$Codec$string),
		A4(
			$miniBill$elm_codec$Codec$field,
			'density',
			function ($) {
				return $.density;
			},
			$miniBill$elm_codec$Codec$string,
			A4(
				$miniBill$elm_codec$Codec$field,
				'gasType',
				function ($) {
					return $.gasType;
				},
				$miniBill$elm_codec$Codec$maybe($miniBill$elm_codec$Codec$string),
				A4(
					$miniBill$elm_codec$Codec$field,
					'bar',
					function ($) {
						return $.bar;
					},
					$miniBill$elm_codec$Codec$float,
					A4(
						$miniBill$elm_codec$Codec$field,
						'characteristic',
						function ($) {
							return $.characteristic;
						},
						$miniBill$elm_codec$Codec$string,
						A4(
							$miniBill$elm_codec$Codec$field,
							'taint',
							function ($) {
								return $.taint;
							},
							$author$project$Traveller$StellarTaint$codecStellarTaint,
							A4(
								$miniBill$elm_codec$Codec$field,
								'irritant',
								function ($) {
									return $.irritant;
								},
								$miniBill$elm_codec$Codec$bool,
								A4(
									$miniBill$elm_codec$Codec$field,
									'code',
									function ($) {
										return $.code;
									},
									$miniBill$elm_codec$Codec$int,
									$miniBill$elm_codec$Codec$object($author$project$Traveller$Atmosphere$StellarAtmosphere))))))))));
var $author$project$Traveller$StellarObject$Hydrographics = F2(
	function (code, distribution) {
		return {code: code, distribution: distribution};
	});
var $author$project$Traveller$StellarObject$codecHydrographics = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'distribution',
		function ($) {
			return $.distribution;
		},
		$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$int),
		A4(
			$miniBill$elm_codec$Codec$field,
			'code',
			function ($) {
				return $.code;
			},
			$miniBill$elm_codec$Codec$int,
			$miniBill$elm_codec$Codec$object($author$project$Traveller$StellarObject$Hydrographics))));
var $author$project$Traveller$StellarObject$codecSharedPData = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'au',
		function ($) {
			return $.au;
		},
		$miniBill$elm_codec$Codec$float,
		A4(
			$miniBill$elm_codec$Codec$field,
			'orbit_type',
			function ($) {
				return $.orbitType;
			},
			$miniBill$elm_codec$Codec$int,
			A4(
				$miniBill$elm_codec$Codec$field,
				'safe_jump_time',
				function ($) {
					return $.safeJumpTime;
				},
				$miniBill$elm_codec$Codec$string,
				A4(
					$miniBill$elm_codec$Codec$optionalNullableField,
					'escape_velocity',
					function ($) {
						return $.escapeVelocity;
					},
					$miniBill$elm_codec$Codec$float,
					A4(
						$miniBill$elm_codec$Codec$optionalNullableField,
						'mass',
						function ($) {
							return $.mass;
						},
						$miniBill$elm_codec$Codec$float,
						A4(
							$miniBill$elm_codec$Codec$optionalNullableField,
							'gravity',
							function ($) {
								return $.gravity;
							},
							$miniBill$elm_codec$Codec$float,
							A4(
								$miniBill$elm_codec$Codec$field,
								'diameter',
								function ($) {
									return $.diameter;
								},
								$miniBill$elm_codec$Codec$float,
								A4(
									$miniBill$elm_codec$Codec$field,
									'uwp',
									function ($) {
										return $.uwp;
									},
									$miniBill$elm_codec$Codec$string,
									A4(
										$miniBill$elm_codec$Codec$field,
										'orbit_sequence',
										function ($) {
											return $.orbitSequence;
										},
										$miniBill$elm_codec$Codec$string,
										A4(
											$miniBill$elm_codec$Codec$optionalField,
											'habitability_rating',
											function ($) {
												return $.habitabilityRating;
											},
											$miniBill$elm_codec$Codec$int,
											A4(
												$miniBill$elm_codec$Codec$optionalNullableField,
												'temperature',
												function ($) {
													return $.meanTemperature;
												},
												$miniBill$elm_codec$Codec$float,
												A4(
													$miniBill$elm_codec$Codec$optionalField,
													'greenhouse',
													function ($) {
														return $.greenhouse;
													},
													$miniBill$elm_codec$Codec$float,
													A4(
														$miniBill$elm_codec$Codec$optionalField,
														'density',
														function ($) {
															return $.density;
														},
														$miniBill$elm_codec$Codec$float,
														A4(
															$miniBill$elm_codec$Codec$field,
															'albedo',
															function ($) {
																return $.albedo;
															},
															$miniBill$elm_codec$Codec$float,
															A4(
																$miniBill$elm_codec$Codec$optionalField,
																'hydrographics',
																function ($) {
																	return $.hydrographics;
																},
																$author$project$Traveller$StellarObject$codecHydrographics,
																A4(
																	$miniBill$elm_codec$Codec$optionalField,
																	'has_ring',
																	function (d) {
																		return $elm$core$Maybe$Just(d.hasRing);
																	},
																	$miniBill$elm_codec$Codec$bool,
																	A4(
																		$miniBill$elm_codec$Codec$field,
																		'extinct_sophont',
																		function ($) {
																			return $.extinctSophont;
																		},
																		$miniBill$elm_codec$Codec$bool,
																		A4(
																			$miniBill$elm_codec$Codec$field,
																			'native_sophont',
																			function ($) {
																				return $.nativeSophont;
																			},
																			$miniBill$elm_codec$Codec$bool,
																			A4(
																				$miniBill$elm_codec$Codec$field,
																				'resource_rating',
																				function ($) {
																					return $.resourceRating;
																				},
																				$miniBill$elm_codec$Codec$int,
																				A4(
																					$miniBill$elm_codec$Codec$field,
																					'compatibility_rating',
																					function ($) {
																						return $.compatibilityRating;
																					},
																					$miniBill$elm_codec$Codec$int,
																					A4(
																						$miniBill$elm_codec$Codec$field,
																						'biodiversity_rating',
																						function ($) {
																							return $.biodiversityRating;
																						},
																						$miniBill$elm_codec$Codec$int,
																						A4(
																							$miniBill$elm_codec$Codec$field,
																							'biocomplexity_rating',
																							function ($) {
																								return $.biocomplexityCode;
																							},
																							$miniBill$elm_codec$Codec$int,
																							A4(
																								$miniBill$elm_codec$Codec$field,
																								'biomass_rating',
																								function ($) {
																									return $.biomassRating;
																								},
																								$miniBill$elm_codec$Codec$int,
																								A4(
																									$miniBill$elm_codec$Codec$field,
																									'moons',
																									function ($) {
																										return $.moons;
																									},
																									A2(
																										$miniBill$elm_codec$Codec$build,
																										$miniBill$elm_codec$Codec$encoder(
																											$miniBill$elm_codec$Codec$list(
																												$miniBill$elm_codec$Codec$lazy(
																													function (_v0) {
																														return $author$project$Traveller$Moon$codec;
																													}))),
																										$elm$json$Json$Decode$oneOf(
																											_List_fromArray(
																												[
																													$miniBill$elm_codec$Codec$decoder(
																													$miniBill$elm_codec$Codec$list(
																														$miniBill$elm_codec$Codec$lazy(
																															function (_v1) {
																																return $author$project$Traveller$Moon$codec;
																															}))),
																													$elm$json$Json$Decode$succeed(_List_Nil)
																												]))),
																									A4(
																										$miniBill$elm_codec$Codec$field,
																										'axial_tilt',
																										function ($) {
																											return $.axialTilt;
																										},
																										$miniBill$elm_codec$Codec$float,
																										A4(
																											$miniBill$elm_codec$Codec$optionalNullableField,
																											'trojan_offset',
																											function ($) {
																												return $.trojanOffset;
																											},
																											$miniBill$elm_codec$Codec$float,
																											A4(
																												$miniBill$elm_codec$Codec$field,
																												'retrograde',
																												function ($) {
																													return $.retrograde;
																												},
																												$miniBill$elm_codec$Codec$bool,
																												A4(
																													$miniBill$elm_codec$Codec$optionalField,
																													'composition',
																													function ($) {
																														return $.composition;
																													},
																													$miniBill$elm_codec$Codec$string,
																													A4(
																														$miniBill$elm_codec$Codec$field,
																														'period',
																														function ($) {
																															return $.period;
																														},
																														$miniBill$elm_codec$Codec$float,
																														A4(
																															$miniBill$elm_codec$Codec$field,
																															'orbit',
																															function ($) {
																																return $.orbit;
																															},
																															$miniBill$elm_codec$Codec$float,
																															A4(
																																$miniBill$elm_codec$Codec$field,
																																'size',
																																function ($) {
																																	return $.size;
																																},
																																A2(
																																	$miniBill$elm_codec$Codec$oneOf,
																																	$miniBill$elm_codec$Codec$string,
																																	_List_fromArray(
																																		[
																																			A3(
																																			$miniBill$elm_codec$Codec$andThen,
																																			A2($elm$core$Basics$composeR, $elm$core$String$fromInt, $miniBill$elm_codec$Codec$succeed),
																																			A2(
																																				$elm$core$Basics$composeR,
																																				$elm$core$String$toInt,
																																				$elm$core$Maybe$withDefault(999999)),
																																			$miniBill$elm_codec$Codec$int)
																																		])),
																																A4(
																																	$miniBill$elm_codec$Codec$field,
																																	'effective_hzco_deviation',
																																	function ($) {
																																		return $.effectiveHZCODeviation;
																																	},
																																	$miniBill$elm_codec$Codec$float,
																																	A4(
																																		$miniBill$elm_codec$Codec$field,
																																		'eccentricity',
																																		function ($) {
																																			return $.eccentricity;
																																		},
																																		$miniBill$elm_codec$Codec$float,
																																		A4(
																																			$miniBill$elm_codec$Codec$field,
																																			'inclination',
																																			function ($) {
																																				return $.inclination;
																																			},
																																			$miniBill$elm_codec$Codec$float,
																																			A4(
																																				$miniBill$elm_codec$Codec$field,
																																				'orbit_position',
																																				function ($) {
																																					return $.orbitPosition;
																																				},
																																				$author$project$Traveller$Point$codec,
																																				A4(
																																					$miniBill$elm_codec$Codec$field,
																																					'atmosphere',
																																					function ($) {
																																						return $.atmosphere;
																																					},
																																					$author$project$Traveller$Atmosphere$codec,
																																					$miniBill$elm_codec$Codec$object(
																																						function (atm) {
																																							return function (pos) {
																																								return function (inc) {
																																									return function (ecc) {
																																										return function (hzco) {
																																											return function (sz) {
																																												return function (orb) {
																																													return function (per) {
																																														return function (comp) {
																																															return function (ret) {
																																																return function (tj) {
																																																	return function (axTilt) {
																																																		return function (mns) {
																																																			return function (bio) {
																																																				return function (bioC) {
																																																					return function (bioDiv) {
																																																						return function (compat) {
																																																							return function (res) {
																																																								return function (natS) {
																																																									return function (extS) {
																																																										return function (hasRingM) {
																																																											return function (hydro) {
																																																												return function (alb) {
																																																													return function (den) {
																																																														return function (grn) {
																																																															return function (temp) {
																																																																return function (hab) {
																																																																	return function (orbitSeq) {
																																																																		return function (uwp_) {
																																																																			return function (diam) {
																																																																				return function (grav) {
																																																																					return function (mass_) {
																																																																						return function (escV) {
																																																																							return function (sjt) {
																																																																								return function (ot) {
																																																																									return function (au) {
																																																																										return {
																																																																											albedo: alb,
																																																																											atmosphere: atm,
																																																																											au: au,
																																																																											axialTilt: axTilt,
																																																																											biocomplexityCode: bioC,
																																																																											biodiversityRating: bioDiv,
																																																																											biomassRating: bio,
																																																																											compatibilityRating: compat,
																																																																											composition: comp,
																																																																											density: den,
																																																																											diameter: diam,
																																																																											eccentricity: ecc,
																																																																											effectiveHZCODeviation: hzco,
																																																																											escapeVelocity: escV,
																																																																											extinctSophont: extS,
																																																																											gravity: grav,
																																																																											greenhouse: grn,
																																																																											habitabilityRating: hab,
																																																																											hasRing: A2($elm$core$Maybe$withDefault, false, hasRingM),
																																																																											hydrographics: hydro,
																																																																											inclination: inc,
																																																																											mass: mass_,
																																																																											meanTemperature: temp,
																																																																											moons: mns,
																																																																											nativeSophont: natS,
																																																																											orbit: orb,
																																																																											orbitPosition: pos,
																																																																											orbitSequence: orbitSeq,
																																																																											orbitType: ot,
																																																																											period: per,
																																																																											resourceRating: res,
																																																																											retrograde: ret,
																																																																											safeJumpTime: sjt,
																																																																											size: sz,
																																																																											trojanOffset: tj,
																																																																											uwp: uwp_
																																																																										};
																																																																									};
																																																																								};
																																																																							};
																																																																						};
																																																																					};
																																																																				};
																																																																			};
																																																																		};
																																																																	};
																																																																};
																																																															};
																																																														};
																																																													};
																																																												};
																																																											};
																																																										};
																																																									};
																																																								};
																																																							};
																																																						};
																																																					};
																																																				};
																																																			};
																																																		};
																																																	};
																																																};
																																															};
																																														};
																																													};
																																												};
																																											};
																																										};
																																									};
																																								};
																																							};
																																						}))))))))))))))))))))))))))))))))))))));
var $miniBill$elm_codec$Codec$encodeToValue = function (codec) {
	return $miniBill$elm_codec$Codec$encoder(codec);
};
var $author$project$Traveller$StellarObject$encodeStellarObject = function (stellarObject) {
	switch (stellarObject.$) {
		case 'GasGiant':
			var data = stellarObject.a;
			return A2($miniBill$elm_codec$Codec$encodeToValue, $author$project$Traveller$StellarObject$codecGasGiantData, data);
		case 'TerrestrialPlanet':
			var data = stellarObject.a;
			return A2($miniBill$elm_codec$Codec$encodeToValue, $author$project$Traveller$StellarObject$codecSharedPData, data);
		case 'PlanetoidBelt':
			var data = stellarObject.a;
			return A2($miniBill$elm_codec$Codec$encodeToValue, $author$project$Traveller$StellarObject$codecPlanetoidBeltData, data);
		case 'Planetoid':
			var data = stellarObject.a;
			return A2($miniBill$elm_codec$Codec$encodeToValue, $author$project$Traveller$StellarObject$codecSharedPData, data);
		default:
			var data = stellarObject.a;
			return A2(
				$miniBill$elm_codec$Codec$encodeToValue,
				$author$project$Traveller$StellarObject$cyclic$codecStarData(),
				data);
	}
};
function $author$project$Traveller$StellarObject$cyclic$codecStarData() {
	return A3(
		$miniBill$elm_codec$Codec$map,
		$author$project$Traveller$StellarObject$StarDataWrap,
		function (_v4) {
			var data = _v4.a;
			return data;
		},
		$miniBill$elm_codec$Codec$buildObject(
			A4(
				$miniBill$elm_codec$Codec$field,
				'jump_shadow',
				function ($) {
					return $.jumpShadow;
				},
				$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$float),
				A4(
					$miniBill$elm_codec$Codec$field,
					'au',
					function ($) {
						return $.au;
					},
					$miniBill$elm_codec$Codec$float,
					A4(
						$miniBill$elm_codec$Codec$field,
						'safe_jump_time',
						function ($) {
							return $.safeJumpTime;
						},
						$miniBill$elm_codec$Codec$string,
						A4(
							$miniBill$elm_codec$Codec$field,
							'orbit_sequence',
							function ($) {
								return $.orbitSequence;
							},
							$miniBill$elm_codec$Codec$string,
							A4(
								$miniBill$elm_codec$Codec$field,
								'stellar_objects',
								function ($) {
									return $.stellarObjects;
								},
								$miniBill$elm_codec$Codec$list(
									$miniBill$elm_codec$Codec$lazy(
										function (_v3) {
											return $author$project$Traveller$StellarObject$cyclic$codecStellarObject();
										})),
								A4(
									$miniBill$elm_codec$Codec$field,
									'baseline',
									function ($) {
										return $.baseline;
									},
									$miniBill$elm_codec$Codec$int,
									A4(
										$miniBill$elm_codec$Codec$field,
										'period',
										function ($) {
											return $.period;
										},
										$miniBill$elm_codec$Codec$float,
										A4(
											$miniBill$elm_codec$Codec$field,
											'orbit',
											function ($) {
												return $.orbit;
											},
											$miniBill$elm_codec$Codec$float,
											A4(
												$miniBill$elm_codec$Codec$field,
												'companion',
												function ($) {
													return $.companion;
												},
												$miniBill$elm_codec$Codec$nullable(
													$miniBill$elm_codec$Codec$lazy(
														function (_v2) {
															return $author$project$Traveller$StellarObject$cyclic$codecStarData();
														})),
												A4(
													$miniBill$elm_codec$Codec$optionalField,
													'colour',
													function ($) {
														return $.colour;
													},
													$author$project$Traveller$StarColour$codecStarColour,
													A4(
														$miniBill$elm_codec$Codec$field,
														'age',
														function ($) {
															return $.age;
														},
														$miniBill$elm_codec$Codec$float,
														A4(
															$miniBill$elm_codec$Codec$field,
															'temperature',
															function ($) {
																return $.temperature;
															},
															$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$int),
															A4(
																$miniBill$elm_codec$Codec$field,
																'diameter',
																function ($) {
																	return $.diameter;
																},
																$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$float),
																A4(
																	$miniBill$elm_codec$Codec$field,
																	'mass',
																	function ($) {
																		return $.mass;
																	},
																	$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$float),
																	A4(
																		$miniBill$elm_codec$Codec$field,
																		'orbit_type',
																		function ($) {
																			return $.orbitType;
																		},
																		$miniBill$elm_codec$Codec$int,
																		A4(
																			$miniBill$elm_codec$Codec$field,
																			'stellar_subtype',
																			function ($) {
																				return $.subtype;
																			},
																			$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$int),
																			A4(
																				$miniBill$elm_codec$Codec$field,
																				'stellar_type',
																				function ($) {
																					return $.stellarType;
																				},
																				$miniBill$elm_codec$Codec$string,
																				A4(
																					$miniBill$elm_codec$Codec$field,
																					'stellar_class',
																					function ($) {
																						return $.stellarClass;
																					},
																					$miniBill$elm_codec$Codec$string,
																					A4(
																						$miniBill$elm_codec$Codec$field,
																						'effective_hzco_deviation',
																						function ($) {
																							return $.effectiveHZCODeviation;
																						},
																						$miniBill$elm_codec$Codec$float,
																						A4(
																							$miniBill$elm_codec$Codec$field,
																							'eccentricity',
																							function ($) {
																								return $.eccentricity;
																							},
																							$miniBill$elm_codec$Codec$float,
																							A4(
																								$miniBill$elm_codec$Codec$field,
																								'inclination',
																								function ($) {
																									return $.inclination;
																								},
																								$miniBill$elm_codec$Codec$float,
																								A4(
																									$miniBill$elm_codec$Codec$field,
																									'orbit_position',
																									function ($) {
																										return $.orbitPosition;
																									},
																									$author$project$Traveller$Point$codec,
																									$miniBill$elm_codec$Codec$object($author$project$Traveller$StellarObject$InnerStarData)))))))))))))))))))))))));
}
function $author$project$Traveller$StellarObject$cyclic$codecStellarObject() {
	return A2(
		$miniBill$elm_codec$Codec$build,
		$author$project$Traveller$StellarObject$encodeStellarObject,
		$author$project$Traveller$StellarObject$cyclic$decodeStellarObject());
}
function $author$project$Traveller$StellarObject$cyclic$decodeStellarObject() {
	return A2(
		$elm$json$Json$Decode$andThen,
		function (orbitType) {
			switch (orbitType) {
				case 10:
					return A2(
						$elm$json$Json$Decode$map,
						$author$project$Traveller$StellarObject$GasGiant,
						$miniBill$elm_codec$Codec$decoder($author$project$Traveller$StellarObject$codecGasGiantData));
				case 11:
					return A2(
						$elm$json$Json$Decode$map,
						$author$project$Traveller$StellarObject$TerrestrialPlanet,
						$miniBill$elm_codec$Codec$decoder($author$project$Traveller$StellarObject$codecSharedPData));
				case 12:
					return A2(
						$elm$json$Json$Decode$map,
						$author$project$Traveller$StellarObject$PlanetoidBelt,
						$miniBill$elm_codec$Codec$decoder($author$project$Traveller$StellarObject$codecPlanetoidBeltData));
				case 13:
					return A2(
						$elm$json$Json$Decode$map,
						$author$project$Traveller$StellarObject$Planetoid,
						$miniBill$elm_codec$Codec$decoder($author$project$Traveller$StellarObject$codecSharedPData));
				default:
					return A2(
						$elm$json$Json$Decode$map,
						$author$project$Traveller$StellarObject$Star,
						$miniBill$elm_codec$Codec$decoder(
							$author$project$Traveller$StellarObject$cyclic$codecStarData()));
			}
		},
		A2($elm$json$Json$Decode$field, 'orbit_type', $elm$json$Json$Decode$int));
}
try {
	var $author$project$Traveller$StellarObject$codecStarData = $author$project$Traveller$StellarObject$cyclic$codecStarData();
	$author$project$Traveller$StellarObject$cyclic$codecStarData = function () {
		return $author$project$Traveller$StellarObject$codecStarData;
	};
	var $author$project$Traveller$StellarObject$codecStellarObject = $author$project$Traveller$StellarObject$cyclic$codecStellarObject();
	$author$project$Traveller$StellarObject$cyclic$codecStellarObject = function () {
		return $author$project$Traveller$StellarObject$codecStellarObject;
	};
	var $author$project$Traveller$StellarObject$decodeStellarObject = $author$project$Traveller$StellarObject$cyclic$decodeStellarObject();
	$author$project$Traveller$StellarObject$cyclic$decodeStellarObject = function () {
		return $author$project$Traveller$StellarObject$decodeStellarObject;
	};
} catch ($) {
	throw 'Some top-level definitions from `Traveller.StellarObject` are causing infinite recursion:\n\n  ┌─────┐\n  │    codecStarData\n  │     ↓\n  │    codecStellarObject\n  │     ↓\n  │    decodeStellarObject\n  │     ↓\n  │    encodeStellarObject\n  └─────┘\n\nThese errors are very tricky, so read https://elm-lang.org/0.19.1/bad-recursion to learn how to fix it!';}
var $author$project$Traveller$SolarSystem$rawCodec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'sector_name',
		function ($) {
			return $.sectorName;
		},
		$miniBill$elm_codec$Codec$string,
		A4(
			$miniBill$elm_codec$Codec$field,
			'name',
			function ($) {
				return $.name;
			},
			$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$string),
			A4(
				$miniBill$elm_codec$Codec$field,
				'allegiance',
				function ($) {
					return $.allegiance;
				},
				$miniBill$elm_codec$Codec$nullable($miniBill$elm_codec$Codec$string),
				A4(
					$miniBill$elm_codec$Codec$field,
					'sector_y',
					function ($) {
						return $.sectorY;
					},
					$miniBill$elm_codec$Codec$int,
					A4(
						$miniBill$elm_codec$Codec$field,
						'sector_x',
						function ($) {
							return $.sectorX;
						},
						$miniBill$elm_codec$Codec$int,
						A4(
							$miniBill$elm_codec$Codec$field,
							'extinct_sophont',
							function ($) {
								return $.extinctSophont;
							},
							$miniBill$elm_codec$Codec$bool,
							A4(
								$miniBill$elm_codec$Codec$field,
								'native_sophont',
								function ($) {
									return $.nativeSophont;
								},
								$miniBill$elm_codec$Codec$bool,
								A4(
									$miniBill$elm_codec$Codec$field,
									'survey_index',
									function ($) {
										return $.surveyIndex;
									},
									$miniBill$elm_codec$Codec$int,
									A4(
										$miniBill$elm_codec$Codec$field,
										'terrestrial_count',
										function ($) {
											return $.terrestrialPlanets;
										},
										$miniBill$elm_codec$Codec$int,
										A4(
											$miniBill$elm_codec$Codec$field,
											'belt_count',
											function ($) {
												return $.planetoidBelts;
											},
											$miniBill$elm_codec$Codec$int,
											A4(
												$miniBill$elm_codec$Codec$field,
												'gas_giant_count',
												function ($) {
													return $.gasGiants;
												},
												$miniBill$elm_codec$Codec$int,
												A4(
													$miniBill$elm_codec$Codec$field,
													'primary_star',
													function ($) {
														return $.primaryStar;
													},
													$author$project$Traveller$StellarObject$codecStarData,
													A4(
														$miniBill$elm_codec$Codec$field,
														'y',
														function ($) {
															return $.y;
														},
														$miniBill$elm_codec$Codec$int,
														A4(
															$miniBill$elm_codec$Codec$field,
															'x',
															function ($) {
																return $.x;
															},
															$miniBill$elm_codec$Codec$int,
															$miniBill$elm_codec$Codec$object($author$project$Traveller$SolarSystem$RawSolarSystem))))))))))))))));
var $author$project$Traveller$SolarSystem$rawToFinal = function (rawSolarSystem) {
	return $miniBill$elm_codec$Codec$succeed(
		{
			address: $author$project$Traveller$HexAddress$createFromStarSystem(rawSolarSystem),
			allegiance: rawSolarSystem.allegiance,
			extinctSophont: rawSolarSystem.extinctSophont,
			gasGiants: rawSolarSystem.gasGiants,
			name: rawSolarSystem.name,
			nativeSophont: rawSolarSystem.nativeSophont,
			planetoidBelts: rawSolarSystem.planetoidBelts,
			primaryStar: rawSolarSystem.primaryStar,
			sectorName: rawSolarSystem.sectorName,
			surveyIndex: rawSolarSystem.surveyIndex,
			terrestrialPlanets: rawSolarSystem.terrestrialPlanets
		});
};
var $author$project$Traveller$SolarSystem$codec = A3($miniBill$elm_codec$Codec$andThen, $author$project$Traveller$SolarSystem$rawToFinal, $author$project$Traveller$SolarSystem$finalToRaw, $author$project$Traveller$SolarSystem$rawCodec);
var $author$project$Traveller$fetchSingleSolarSystemRequest = F2(
	function (hostConfig, hex) {
		var solarSystemDecoder = $miniBill$elm_codec$Codec$decoder($author$project$Traveller$SolarSystem$codec);
		var _v0 = hostConfig;
		var urlHostRoot = _v0.a;
		var urlHostPath = _v0.b;
		var url = A3(
			$elm$url$Url$Builder$crossOrigin,
			urlHostRoot,
			_Utils_ap(
				urlHostPath,
				_List_fromArray(
					['starsystem'])),
			_List_fromArray(
				[
					A2($elm$url$Url$Builder$int, 'sx', hex.sectorX),
					A2($elm$url$Url$Builder$int, 'sy', hex.sectorY),
					A2($elm$url$Url$Builder$int, 'hx', hex.x + 1),
					A2($elm$url$Url$Builder$int, 'hy', hex.y + 1)
				]));
		var requestCmd = $elm$http$Http$request(
			{
				body: $elm$http$Http$emptyBody,
				expect: A2($elm$http$Http$expectJson, $author$project$Traveller$FetchedSolarSystem, solarSystemDecoder),
				headers: _List_Nil,
				method: 'GET',
				timeout: $elm$core$Maybe$Just(5000),
				tracker: $elm$core$Maybe$Nothing,
				url: url
			});
		return requestCmd;
	});
var $cuducos$elm_format_number$FormatNumber$Parser$FormattedNumber = F5(
	function (original, integers, decimals, prefix, suffix) {
		return {decimals: decimals, integers: integers, original: original, prefix: prefix, suffix: suffix};
	});
var $cuducos$elm_format_number$FormatNumber$Parser$Negative = {$: 'Negative'};
var $cuducos$elm_format_number$FormatNumber$Parser$Positive = {$: 'Positive'};
var $cuducos$elm_format_number$FormatNumber$Parser$Zero = {$: 'Zero'};
var $elm$core$String$concat = function (strings) {
	return A2($elm$core$String$join, '', strings);
};
var $elm$core$List$singleton = function (value) {
	return _List_fromArray(
		[value]);
};
var $cuducos$elm_format_number$FormatNumber$Parser$classify = function (formatted) {
	var onlyZeros = A2(
		$elm$core$String$all,
		function (_char) {
			return _Utils_eq(
				_char,
				_Utils_chr('0'));
		},
		$elm$core$String$concat(
			A2(
				$elm$core$List$append,
				formatted.integers,
				$elm$core$List$singleton(formatted.decimals))));
	return onlyZeros ? $cuducos$elm_format_number$FormatNumber$Parser$Zero : ((formatted.original < 0) ? $cuducos$elm_format_number$FormatNumber$Parser$Negative : $cuducos$elm_format_number$FormatNumber$Parser$Positive);
};
var $elm$core$String$filter = _String_filter;
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $cuducos$elm_format_number$FormatNumber$Parser$addZerosToFit = F2(
	function (desiredLength, value) {
		var length = $elm$core$String$length(value);
		var missing = (_Utils_cmp(length, desiredLength) < 0) ? $elm$core$Basics$abs(desiredLength - length) : 0;
		return _Utils_ap(
			value,
			A2($elm$core$String$repeat, missing, '0'));
	});
var $elm$core$String$dropRight = F2(
	function (n, string) {
		return (n < 1) ? string : A3($elm$core$String$slice, 0, -n, string);
	});
var $elm$core$String$right = F2(
	function (n, string) {
		return (n < 1) ? '' : A3(
			$elm$core$String$slice,
			-n,
			$elm$core$String$length(string),
			string);
	});
var $cuducos$elm_format_number$FormatNumber$Parser$removeZeros = function (decimals) {
	return (A2($elm$core$String$right, 1, decimals) !== '0') ? decimals : $cuducos$elm_format_number$FormatNumber$Parser$removeZeros(
		A2($elm$core$String$dropRight, 1, decimals));
};
var $cuducos$elm_format_number$FormatNumber$Parser$getDecimals = F2(
	function (locale, digits) {
		var _v0 = locale.decimals;
		switch (_v0.$) {
			case 'Max':
				return $cuducos$elm_format_number$FormatNumber$Parser$removeZeros(digits);
			case 'Exact':
				return digits;
			default:
				var min = _v0.a;
				return A2($cuducos$elm_format_number$FormatNumber$Parser$addZerosToFit, min, digits);
		}
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$Basics$not = _Basics_not;
var $myrho$elm_round$Round$addSign = F2(
	function (signed, str) {
		var isNotZero = A2(
			$elm$core$List$any,
			function (c) {
				return (!_Utils_eq(
					c,
					_Utils_chr('0'))) && (!_Utils_eq(
					c,
					_Utils_chr('.')));
			},
			$elm$core$String$toList(str));
		return _Utils_ap(
			(signed && isNotZero) ? '-' : '',
			str);
	});
var $myrho$elm_round$Round$increaseNum = function (_v0) {
	var head = _v0.a;
	var tail = _v0.b;
	if (_Utils_eq(
		head,
		_Utils_chr('9'))) {
		var _v1 = $elm$core$String$uncons(tail);
		if (_v1.$ === 'Nothing') {
			return '01';
		} else {
			var headtail = _v1.a;
			return A2(
				$elm$core$String$cons,
				_Utils_chr('0'),
				$myrho$elm_round$Round$increaseNum(headtail));
		}
	} else {
		var c = $elm$core$Char$toCode(head);
		return ((c >= 48) && (c < 57)) ? A2(
			$elm$core$String$cons,
			$elm$core$Char$fromCode(c + 1),
			tail) : '0';
	}
};
var $elm$core$Basics$isInfinite = _Basics_isInfinite;
var $elm$core$Basics$isNaN = _Basics_isNaN;
var $elm$core$String$padRight = F3(
	function (n, _char, string) {
		return _Utils_ap(
			string,
			A2(
				$elm$core$String$repeat,
				n - $elm$core$String$length(string),
				$elm$core$String$fromChar(_char)));
	});
var $myrho$elm_round$Round$splitComma = function (str) {
	var _v0 = A2($elm$core$String$split, '.', str);
	if (_v0.b) {
		if (_v0.b.b) {
			var before = _v0.a;
			var _v1 = _v0.b;
			var after = _v1.a;
			return _Utils_Tuple2(before, after);
		} else {
			var before = _v0.a;
			return _Utils_Tuple2(before, '0');
		}
	} else {
		return _Utils_Tuple2('0', '0');
	}
};
var $elm$core$Tuple$mapFirst = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			func(x),
			y);
	});
var $myrho$elm_round$Round$toDecimal = function (fl) {
	var _v0 = A2(
		$elm$core$String$split,
		'e',
		$elm$core$String$fromFloat(
			$elm$core$Basics$abs(fl)));
	if (_v0.b) {
		if (_v0.b.b) {
			var num = _v0.a;
			var _v1 = _v0.b;
			var exp = _v1.a;
			var e = A2(
				$elm$core$Maybe$withDefault,
				0,
				$elm$core$String$toInt(
					A2($elm$core$String$startsWith, '+', exp) ? A2($elm$core$String$dropLeft, 1, exp) : exp));
			var _v2 = $myrho$elm_round$Round$splitComma(num);
			var before = _v2.a;
			var after = _v2.b;
			var total = _Utils_ap(before, after);
			var zeroed = (e < 0) ? A2(
				$elm$core$Maybe$withDefault,
				'0',
				A2(
					$elm$core$Maybe$map,
					function (_v3) {
						var a = _v3.a;
						var b = _v3.b;
						return a + ('.' + b);
					},
					A2(
						$elm$core$Maybe$map,
						$elm$core$Tuple$mapFirst($elm$core$String$fromChar),
						$elm$core$String$uncons(
							_Utils_ap(
								A2(
									$elm$core$String$repeat,
									$elm$core$Basics$abs(e),
									'0'),
								total))))) : A3(
				$elm$core$String$padRight,
				e + 1,
				_Utils_chr('0'),
				total);
			return _Utils_ap(
				(fl < 0) ? '-' : '',
				zeroed);
		} else {
			var num = _v0.a;
			return _Utils_ap(
				(fl < 0) ? '-' : '',
				num);
		}
	} else {
		return '';
	}
};
var $myrho$elm_round$Round$roundFun = F3(
	function (functor, s, fl) {
		if ($elm$core$Basics$isInfinite(fl) || $elm$core$Basics$isNaN(fl)) {
			return $elm$core$String$fromFloat(fl);
		} else {
			var signed = fl < 0;
			var _v0 = $myrho$elm_round$Round$splitComma(
				$myrho$elm_round$Round$toDecimal(
					$elm$core$Basics$abs(fl)));
			var before = _v0.a;
			var after = _v0.b;
			var r = $elm$core$String$length(before) + s;
			var normalized = _Utils_ap(
				A2($elm$core$String$repeat, (-r) + 1, '0'),
				A3(
					$elm$core$String$padRight,
					r,
					_Utils_chr('0'),
					_Utils_ap(before, after)));
			var totalLen = $elm$core$String$length(normalized);
			var roundDigitIndex = A2($elm$core$Basics$max, 1, r);
			var increase = A2(
				functor,
				signed,
				A3($elm$core$String$slice, roundDigitIndex, totalLen, normalized));
			var remains = A3($elm$core$String$slice, 0, roundDigitIndex, normalized);
			var num = increase ? $elm$core$String$reverse(
				A2(
					$elm$core$Maybe$withDefault,
					'1',
					A2(
						$elm$core$Maybe$map,
						$myrho$elm_round$Round$increaseNum,
						$elm$core$String$uncons(
							$elm$core$String$reverse(remains))))) : remains;
			var numLen = $elm$core$String$length(num);
			var numZeroed = (num === '0') ? num : ((s <= 0) ? _Utils_ap(
				num,
				A2(
					$elm$core$String$repeat,
					$elm$core$Basics$abs(s),
					'0')) : ((_Utils_cmp(
				s,
				$elm$core$String$length(after)) < 0) ? (A3($elm$core$String$slice, 0, numLen - s, num) + ('.' + A3($elm$core$String$slice, numLen - s, numLen, num))) : _Utils_ap(
				before + '.',
				A3(
					$elm$core$String$padRight,
					s,
					_Utils_chr('0'),
					after))));
			return A2($myrho$elm_round$Round$addSign, signed, numZeroed);
		}
	});
var $myrho$elm_round$Round$round = $myrho$elm_round$Round$roundFun(
	F2(
		function (signed, str) {
			var _v0 = $elm$core$String$uncons(str);
			if (_v0.$ === 'Nothing') {
				return false;
			} else {
				if ('5' === _v0.a.a.valueOf()) {
					if (_v0.a.b === '') {
						var _v1 = _v0.a;
						return !signed;
					} else {
						var _v2 = _v0.a;
						return true;
					}
				} else {
					var _v3 = _v0.a;
					var _int = _v3.a;
					return function (i) {
						return ((i > 53) && signed) || ((i >= 53) && (!signed));
					}(
						$elm$core$Char$toCode(_int));
				}
			}
		}));
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $cuducos$elm_format_number$FormatNumber$Parser$splitInParts = F2(
	function (locale, value) {
		var toString = function () {
			var _v1 = locale.decimals;
			switch (_v1.$) {
				case 'Max':
					var max = _v1.a;
					return $myrho$elm_round$Round$round(max);
				case 'Min':
					return $elm$core$String$fromFloat;
				default:
					var exact = _v1.a;
					return $myrho$elm_round$Round$round(exact);
			}
		}();
		var asList = A2(
			$elm$core$String$split,
			'.',
			toString(value));
		var decimals = function () {
			var _v0 = $elm$core$List$tail(asList);
			if (_v0.$ === 'Just') {
				var values = _v0.a;
				return A2(
					$elm$core$Maybe$withDefault,
					'',
					$elm$core$List$head(values));
			} else {
				return '';
			}
		}();
		var integers = A2(
			$elm$core$Maybe$withDefault,
			'',
			$elm$core$List$head(asList));
		return _Utils_Tuple2(integers, decimals);
	});
var $cuducos$elm_format_number$FormatNumber$Parser$splitByIndian = function (integers) {
	var thousand = ($elm$core$String$length(integers) > 3) ? A2($elm$core$String$right, 3, integers) : integers;
	var reversedSplitHundreds = function (value) {
		return ($elm$core$String$length(value) > 2) ? A2(
			$elm$core$List$cons,
			A2($elm$core$String$right, 2, value),
			reversedSplitHundreds(
				A2($elm$core$String$dropRight, 2, value))) : ((!$elm$core$String$length(value)) ? _List_Nil : _List_fromArray(
			[value]));
	};
	return $elm$core$List$reverse(
		A2(
			$elm$core$List$cons,
			thousand,
			reversedSplitHundreds(
				A2($elm$core$String$dropRight, 3, integers))));
};
var $cuducos$elm_format_number$FormatNumber$Parser$splitByWestern = function (integers) {
	var reversedSplitThousands = function (value) {
		return ($elm$core$String$length(value) > 3) ? A2(
			$elm$core$List$cons,
			A2($elm$core$String$right, 3, value),
			reversedSplitThousands(
				A2($elm$core$String$dropRight, 3, value))) : _List_fromArray(
			[value]);
	};
	return $elm$core$List$reverse(
		reversedSplitThousands(integers));
};
var $cuducos$elm_format_number$FormatNumber$Parser$splitIntegers = F2(
	function (system, integers) {
		if (system.$ === 'Western') {
			return $cuducos$elm_format_number$FormatNumber$Parser$splitByWestern(
				A2($elm$core$String$filter, $elm$core$Char$isDigit, integers));
		} else {
			return $cuducos$elm_format_number$FormatNumber$Parser$splitByIndian(
				A2($elm$core$String$filter, $elm$core$Char$isDigit, integers));
		}
	});
var $cuducos$elm_format_number$FormatNumber$Parser$parse = F2(
	function (locale, original) {
		var parts = A2($cuducos$elm_format_number$FormatNumber$Parser$splitInParts, locale, original);
		var integers = A2(
			$cuducos$elm_format_number$FormatNumber$Parser$splitIntegers,
			locale.system,
			A2($elm$core$String$filter, $elm$core$Char$isDigit, parts.a));
		var decimals = A2($cuducos$elm_format_number$FormatNumber$Parser$getDecimals, locale, parts.b);
		var partial = A5($cuducos$elm_format_number$FormatNumber$Parser$FormattedNumber, original, integers, decimals, '', '');
		var _v0 = $cuducos$elm_format_number$FormatNumber$Parser$classify(partial);
		switch (_v0.$) {
			case 'Negative':
				return _Utils_update(
					partial,
					{prefix: locale.negativePrefix, suffix: locale.negativeSuffix});
			case 'Positive':
				return _Utils_update(
					partial,
					{prefix: locale.positivePrefix, suffix: locale.positiveSuffix});
			default:
				return _Utils_update(
					partial,
					{prefix: locale.zeroPrefix, suffix: locale.zeroSuffix});
		}
	});
var $cuducos$elm_format_number$FormatNumber$Stringfy$formatDecimals = F2(
	function (locale, decimals) {
		return (decimals === '') ? '' : _Utils_ap(locale.decimalSeparator, decimals);
	});
var $cuducos$elm_format_number$FormatNumber$Stringfy$stringfy = F2(
	function (locale, formatted) {
		var stringfyDecimals = $cuducos$elm_format_number$FormatNumber$Stringfy$formatDecimals(locale);
		var integers = A2($elm$core$String$join, locale.thousandSeparator, formatted.integers);
		var decimals = stringfyDecimals(formatted.decimals);
		return $elm$core$String$concat(
			_List_fromArray(
				[formatted.prefix, integers, decimals, formatted.suffix]));
	});
var $cuducos$elm_format_number$FormatNumber$format = F2(
	function (locale, number_) {
		return A2(
			$cuducos$elm_format_number$FormatNumber$Stringfy$stringfy,
			locale,
			A2($cuducos$elm_format_number$FormatNumber$Parser$parse, locale, number_));
	});
var $author$project$Traveller$fullJourneyImageHeight = 2240;
var $author$project$Traveller$fullJourneyImageWidth = 2176;
var $author$project$Traveller$StellarObject$getProfileString = function (stellarObject) {
	switch (stellarObject.$) {
		case 'GasGiant':
			var gasGiantData = stellarObject.a;
			return gasGiantData.code;
		case 'TerrestrialPlanet':
			var terrestrialData = stellarObject.a;
			return terrestrialData.uwp;
		case 'PlanetoidBelt':
			var planetoidBeltData = stellarObject.a;
			return planetoidBeltData.uwp;
		case 'Planetoid':
			var planetoidData = stellarObject.a;
			return planetoidData.uwp;
		default:
			var starDataConfig = stellarObject.a.a;
			return starDataConfig.stellarType + (A2(
				$elm$core$Maybe$withDefault,
				'',
				A2($elm$core$Maybe$map, $elm$core$String$fromInt, starDataConfig.subtype)) + (' ' + starDataConfig.stellarClass));
	}
};
var $author$project$Traveller$StellarObject$extractStellarOrbit = function (orbit) {
	return {au: orbit.au, orbit: orbit.orbit, orbitPosition: orbit.orbitPosition, orbitSequence: orbit.orbitSequence, orbitType: orbit.orbitType};
};
var $author$project$Traveller$StellarObject$getStellarOrbit = function (stellarObject) {
	switch (stellarObject.$) {
		case 'GasGiant':
			var giantData = stellarObject.a;
			return $author$project$Traveller$StellarObject$extractStellarOrbit(giantData);
		case 'TerrestrialPlanet':
			var terrestrialData = stellarObject.a;
			return $author$project$Traveller$StellarObject$extractStellarOrbit(terrestrialData);
		case 'PlanetoidBelt':
			var planetoidBelt = stellarObject.a;
			return $author$project$Traveller$StellarObject$extractStellarOrbit(planetoidBelt);
		case 'Planetoid':
			var planetoid = stellarObject.a;
			return $author$project$Traveller$StellarObject$extractStellarOrbit(planetoid);
		default:
			var innerStarData = stellarObject.a.a;
			return $author$project$Traveller$StellarObject$extractStellarOrbit(innerStarData);
	}
};
var $elm$browser$Browser$Dom$getViewportOf = _Browser_getViewportOf;
var $author$project$Traveller$Lifeforms$habitabilityDescription = function (maybeRating) {
	var ratingToString = function (rating) {
		switch (rating) {
			case 0:
				return 'Actively hostile world: not survivable without specialised equipment';
			case 1:
				return 'Barely habitable world: full protective equipment often needed';
			case 2:
				return 'Barely habitable world: full protective equipment often needed';
			case 3:
				return 'Marginally survivable world with proper equipment';
			case 4:
				return 'Marginally survivable world with proper equipment';
			case 5:
				return 'Marginally survivable world with proper equipment';
			case 6:
				return 'Regionally habitable world: may require acclimation';
			case 7:
				return 'Regionally habitable world: may require acclimation';
			case 8:
				return 'Suitable for human habitation with minimal equipment or acclimation';
			case 9:
				return 'Suitable for human habitation with minimal equipment or acclimation';
			default:
				return 'Terra-equivalent garden world';
		}
	};
	return A2(
		$elm$core$Maybe$withDefault,
		'N/A',
		A2($elm$core$Maybe$map, ratingToString, maybeRating));
};
var $author$project$Traveller$defaultHorizontalHexes = 30;
var $author$project$Traveller$HexGeometry$hexWidth = function (hexScale) {
	return hexScale * (1.0 + $elm$core$Basics$cos($author$project$Traveller$HexGeometry$hexSizeFactor));
};
var $author$project$Traveller$horizontalHexes = F2(
	function (hexmapViewport, hexScale) {
		if (hexmapViewport.$ === 'Just') {
			var vp = hexmapViewport.a;
			if (vp.$ === 'Ok') {
				var viewport = vp.a;
				return $elm$core$Basics$floor(
					viewport.viewport.width / $author$project$Traveller$HexGeometry$hexWidth(hexScale));
			} else {
				return $author$project$Traveller$defaultHorizontalHexes;
			}
		} else {
			return $author$project$Traveller$defaultHorizontalHexes;
		}
	});
var $author$project$Traveller$Hydrographics$hydrographicsPercentageDescription = function (code) {
	return $elm$core$String$fromInt(code * 10) + '%';
};
var $elm_community$result_extra$Result$Extra$isErr = function (x) {
	if (x.$ === 'Ok') {
		return false;
	} else {
		return true;
	}
};
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $krisajenkins$remotedata$RemoteData$NotAsked = {$: 'NotAsked'};
var $author$project$Traveller$stripDataFromRemoteData = function (remoteData) {
	switch (remoteData.$) {
		case 'Success':
			return $krisajenkins$remotedata$RemoteData$Success(_Utils_Tuple0);
		case 'Failure':
			var err = remoteData.a;
			return $krisajenkins$remotedata$RemoteData$Failure(err);
		case 'NotAsked':
			return $krisajenkins$remotedata$RemoteData$NotAsked;
		default:
			return $krisajenkins$remotedata$RemoteData$Loading;
	}
};
var $author$project$Traveller$markRequestComplete = F3(
	function (requestEntry, remoteData, requestHistory) {
		return A2(
			$elm$core$List$map,
			function (entry) {
				return _Utils_eq(entry.requestNum, requestEntry.requestNum) ? _Utils_update(
					entry,
					{
						status: $author$project$Traveller$stripDataFromRemoteData(remoteData)
					}) : entry;
			},
			requestHistory);
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $author$project$Traveller$mouseCoordsToSector = F3(
	function (mousePos, offset, imageSize) {
		var _v0 = _Utils_Tuple2(17, 14);
		var sectorsAcross = _v0.a;
		var sectorsTall = _v0.b;
		var _v1 = _Utils_Tuple2((mousePos.x - offset.x) / (imageSize.width / sectorsAcross), (mousePos.y - offset.y) / (imageSize.height / sectorsTall));
		var sectorX = _v1.a;
		var sectorY = _v1.b;
		var _v2 = function () {
			var _v3 = _Utils_Tuple2(5, 1);
			var oursX = _v3.a;
			var oursY = _v3.b;
			var _v4 = _Utils_Tuple2(-21, -2);
			var officialX = _v4.a;
			var officialY = _v4.b;
			return _Utils_Tuple2(officialX - oursX, officialY + oursY);
		}();
		var correctedX = _v2.a;
		var correctedY = _v2.b;
		return {
			x: correctedX + $elm$core$Basics$floor(sectorX),
			y: correctedY - $elm$core$Basics$floor(sectorY)
		};
	});
var $author$project$Traveller$refereeSI = 99;
var $author$project$Traveller$storeHexSize = _Platform_outgoingPort('storeHexSize', $elm$json$Json$Encode$float);
var $author$project$Traveller$saveHexSize = function (size) {
	return $author$project$Traveller$storeHexSize(size);
};
var $author$project$Traveller$storeInLocalStorage = _Platform_outgoingPort(
	'storeInLocalStorage',
	function ($) {
		var a = $.a;
		var b = $.b;
		return A2(
			$elm$json$Json$Encode$list,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					$elm$json$Json$Encode$int(a),
					$elm$json$Json$Encode$int(b)
				]));
	});
var $author$project$Traveller$saveMapCoords = function (upperLeft) {
	return $author$project$Traveller$storeInLocalStorage(
		_Utils_Tuple2(upperLeft.x, upperLeft.y));
};
var $author$project$Traveller$Sector$sectorKey = function (sector) {
	return $elm$core$String$fromInt(sector.x) + ('.' + $elm$core$String$fromInt(sector.y));
};
var $author$project$Traveller$Sidebar$sidebarWidth = 400;
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $author$project$Traveller$Hydrographics$surfaceDistributionDescription = function (code) {
	if (code.$ === 'Nothing') {
		return 'No liquid present';
	} else {
		switch (code.a) {
			case 0:
				return 'Extremely Dispersed (Many minor and small bodies: no major bodies)';
			case 1:
				return 'Very Dispersed (Mostly minor bodies: 5–10% of the surface coverage is in major bodies)';
			case 2:
				return 'Dispersed (Mostly minor bodies: 10–20% of the surface coverage is in major bodies)';
			case 3:
				return 'Scattered (Roughly 20–30% or less of the surface coverage is in major bodies)';
			case 4:
				return 'Slightly Scattered (Roughly 30–40% or less of the surface coverage is in major bodies)';
			case 5:
				return 'Mixed (Mix of major and minor bodies: roughly 40–60% of body coverage is major)';
			case 6:
				return 'Slightly Skewed (Roughly 60–70% of surface coverage is in major bodies)';
			case 7:
				return 'Skewed (Roughly 70–80% of surface coverage is in major bodies)';
			case 8:
				return 'Concentrated (Mostly major bodies: 80–90% of the surface coverage is in major bodies)';
			case 9:
				return 'Very Concentrated (Single very large major body: 90–95% of body coverage is in one body)';
			case 10:
				return 'Extremely Concentrated (Single very large major body: 95% or more of body coverage is in one body)';
			default:
				return 'Unknown surface distribution code';
		}
	}
};
var $author$project$Traveller$StellarTaint$taintPersistenceDescription = function (code) {
	if (code >= 9) {
		return 'Constant (Ever-present at indicated severity; no roll)';
	} else {
		switch (code) {
			case 2:
				return 'Occasional and brief (Occurs periodically or on a 2D roll of 12 per day; lasts 1D hours)';
			case 3:
				return 'Occasional and lingering (Occurs periodically or on a 2D roll of 12 per day; lasts 1D days)';
			case 4:
				return 'Irregular (Occurs on 2D 9+; lasts D3 days)';
			case 5:
				return 'Fluctuating (Roll 2D daily: on 6- reduce severity by one level; on 12 increase severity by one level)';
			case 6:
				return 'Varying (Always present; roll 2D daily: on 6- reduce severity by one level for 1D hours)';
			case 7:
				return 'Varying (Always present; roll 2D daily: on 4- reduce severity by one level for 1D hours)';
			case 8:
				return 'Varying (Always present; roll 2D daily: on 2 reduce severity by one level for 1D hours)';
			default:
				return 'N/A';
		}
	}
};
var $author$project$Traveller$StellarTaint$taintSeverityDescription = function (code) {
	switch (code) {
		case 1:
			return 'Trivial irritant (After 1D weeks acclimation, this taint is inconsequential)';
		case 2:
			return 'Surmountable irritant (After 1D months acclimation, this taint is inconsequential)';
		case 3:
			return 'Minor irritant (Surmountable on Difficult (10+) END check)';
		case 4:
			return 'Major irritant (Filter masks required or TL10+ medical intervention)';
		case 5:
			return 'Serious irritant (Filter masks required or TL12+ medical intervention)';
		case 6:
			return 'Hazardous irritant (Filter masks required or TL14+ medical intervention)';
		case 7:
			return 'Long term lethal: DM-2 to aging rolls (Filter masks required)';
		case 8:
			return 'Inevitably lethal: death within 1D days (Filter masks required; protective clothing recommended)';
		case 9:
			return 'Rapidly lethal: death within 1D minutes (Filter masks and protective clothing required)';
		default:
			return 'N/A';
	}
};
var $elm$core$String$toUpper = _String_toUpper;
var $elm$core$String$trim = _String_trim;
var $author$project$Traveller$StellarTaint$taintSubtypeDescription = function (code) {
	var _v0 = $elm$core$String$toUpper(
		$elm$core$String$trim(code));
	switch (_v0) {
		case 'L':
			return 'Low Oxygen';
		case 'R':
			return 'Radioactivity';
		case 'B':
			return 'Biologic';
		case 'G':
			return 'Gas Mix';
		case 'P':
			return 'Particulates';
		case 'S':
			return 'Sulphur Compounds';
		case 'H':
			return 'High Oxygen';
		default:
			var unknown = _v0;
			return 'N/A' + (' (Unknown subtype: ' + (unknown + ')'));
	}
};
var $elm$core$Result$toMaybe = function (result) {
	if (result.$ === 'Ok') {
		var v = result.a;
		return $elm$core$Maybe$Just(v);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Traveller$HexAddress$universalToSectorX = function (_v0) {
	var x = _v0.x;
	return (x < 0) ? ((-1) + (((x + 1) / 32) | 0)) : ((x / 32) | 0);
};
var $author$project$Traveller$HexAddress$universalToSectorY = function (_v0) {
	var y = _v0.y;
	return (y <= 0) ? ((y / 40) | 0) : (1 + (((y - 1) / 40) | 0));
};
var $author$project$Traveller$HexAddress$toSectorAddress = function (universal) {
	var sectorY = $author$project$Traveller$HexAddress$universalToSectorY(universal);
	var sectorX = $author$project$Traveller$HexAddress$universalToSectorX(universal);
	return {sectorX: sectorX, sectorY: sectorY, x: universal.x - (sectorX * 32), y: (sectorY * 40) - universal.y};
};
var $author$project$Traveller$toXY = function (_v0) {
	var left = _v0.a;
	var right = _v0.b;
	return {x: left, y: right};
};
var $elm$core$Basics$truncate = _Basics_truncate;
var $cuducos$elm_format_number$FormatNumber$Locales$Min = function (a) {
	return {$: 'Min', a: a};
};
var $cuducos$elm_format_number$FormatNumber$Locales$Western = {$: 'Western'};
var $cuducos$elm_format_number$FormatNumber$Locales$base = {
	decimalSeparator: '.',
	decimals: $cuducos$elm_format_number$FormatNumber$Locales$Min(0),
	negativePrefix: '−',
	negativeSuffix: '',
	positivePrefix: '',
	positiveSuffix: '',
	system: $cuducos$elm_format_number$FormatNumber$Locales$Western,
	thousandSeparator: '',
	zeroPrefix: '',
	zeroSuffix: ''
};
var $cuducos$elm_format_number$FormatNumber$Locales$usLocale = _Utils_update(
	$cuducos$elm_format_number$FormatNumber$Locales$base,
	{
		decimals: $cuducos$elm_format_number$FormatNumber$Locales$Exact(2),
		thousandSeparator: ','
	});
var $author$project$Traveller$defaultVerticalHexes = 25;
var $author$project$Traveller$HexGeometry$hexHeight = function (hexScale) {
	return hexScale * (1.0 + $elm$core$Basics$sin($author$project$Traveller$HexGeometry$hexSizeFactor));
};
var $author$project$Traveller$verticalHexes = F2(
	function (hexmapViewport, hexScale) {
		if (hexmapViewport.$ === 'Just') {
			if (hexmapViewport.a.$ === 'Ok') {
				var viewport = hexmapViewport.a.a;
				return $elm$core$Basics$floor(
					viewport.viewport.height / $author$project$Traveller$HexGeometry$hexHeight(hexScale));
			} else {
				return $author$project$Traveller$defaultVerticalHexes;
			}
		} else {
			return $author$project$Traveller$defaultVerticalHexes;
		}
	});
var $author$project$Traveller$update = F2(
	function (msg, _v15) {
		var time = _v15.a;
		var model = _v15.b;
		var withTime = function (m) {
			return _Utils_Tuple2(time, m);
		};
		switch (msg.$) {
			case 'NoOpMsg':
				return _Utils_Tuple2(
					withTime(model),
					$elm$core$Platform$Cmd$none);
			case 'Tick':
				var newTime = msg.a;
				return _Utils_Tuple2(
					_Utils_Tuple2(newTime, model),
					$elm$core$Platform$Cmd$none);
			case 'SetHexSize':
				var newSize = msg.a;
				var extraPaddingHexes = 2;
				var hh = A2($author$project$Traveller$horizontalHexes, model.viewport.hexmapViewport, newSize) + extraPaddingHexes;
				var vh = A2($author$project$Traveller$verticalHexes, model.viewport.hexmapViewport, newSize) + extraPaddingHexes;
				var lr = A2(
					$author$project$Traveller$HexAddress$shiftAddressBy,
					{deltaX: hh, deltaY: vh},
					model.hexRect.upperLeftHex);
				var newHexRect = {lowerRightHex: lr, upperLeftHex: model.hexRect.upperLeftHex};
				var _v17 = function () {
					var _v18 = _Utils_Tuple2(
						_Utils_update(
							model,
							{
								hexRect: newHexRect,
								hexScale: newSize,
								rawHexaPoints: $author$project$Traveller$HexGeometry$rawHexagonPoints(newSize),
								viewMode: $author$project$Traveller$HexMap
							}),
						$author$project$Traveller$saveHexSize(newSize));
					var newModel_ = _v18.a;
					var newCmds_ = _v18.b;
					return A2(
						$elm$core$Tuple$mapSecond,
						function (newestCmds) {
							return $elm$core$Platform$Cmd$batch(
								_List_fromArray(
									[newCmds_, newestCmds]));
						},
						A2(
							$author$project$Traveller$update,
							$author$project$Traveller$DownloadSolarSystems,
							withTime(newModel_)));
				}();
				var newModel = _v17.a;
				var newCmds = _v17.b;
				return _Utils_Tuple2(newModel, newCmds);
			case 'DownloadSolarSystems':
				var _v19 = A2(
					$author$project$Traveller$prepNextRequest,
					_Utils_Tuple2(model.solarSystems, model.requestHistory),
					model.hexRect);
				var nextRequestEntry = _v19.a;
				var _v20 = _v19.b;
				var newSolarSystemDict = _v20.a;
				var newRequestHistory = _v20.b;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{requestHistory: newRequestHistory, solarSystems: newSolarSystemDict})),
					A3($author$project$Traveller$sendSolarSystemRequest, nextRequestEntry, model.hostConfig, model.hexRect));
			case 'DownloadedSectors':
				if (msg.b.$ === 'Ok') {
					var requestEntry = msg.a;
					var sectors = msg.b.a;
					var sectorDict = A3(
						$elm$core$List$foldl,
						F2(
							function (sector, acc) {
								return A3(
									$elm$core$Dict$insert,
									$author$project$Traveller$Sector$sectorKey(sector),
									sector,
									acc);
							}),
						$elm$core$Dict$empty,
						sectors);
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{sectors: sectorDict})),
						$elm$core$Platform$Cmd$none);
				} else {
					var _v26 = msg.a;
					var requestEntry = _v26.a;
					var url = _v26.b;
					var err = msg.b.a;
					var _v27 = A2($elm$core$Debug$log, 'Sectors did not work', err);
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									newSolarSystemErrors: A2(
										$elm$core$List$cons,
										_Utils_Tuple2(err, url),
										model.newSolarSystemErrors)
								})),
						$elm$core$Platform$Cmd$none);
				}
			case 'DownloadedRegions':
				if (msg.b.$ === 'Ok') {
					var requestEntry = msg.a;
					var regions = msg.b.a;
					var regionLabelDict = $elm$core$Dict$fromList(
						A2(
							$elm$core$List$filterMap,
							function (region) {
								return A2(
									$elm$core$Maybe$map,
									function (pos) {
										return _Utils_Tuple2(
											$author$project$Traveller$HexAddress$toKey(pos),
											region.name);
									},
									region.labelPosition);
							},
							regions));
					var regionDict = A3(
						$elm$core$List$foldl,
						F2(
							function (region, acc) {
								return A3($elm$core$Dict$insert, region.id, region, acc);
							}),
						$elm$core$Dict$empty,
						regions);
					var parsecList = function (region) {
						return A2(
							$elm$core$List$map,
							function (p) {
								return _Utils_Tuple2(
									$author$project$Traveller$HexAddress$toKey(p),
									region.colour);
							},
							region.hexes);
					};
					var hexColourDict = $elm$core$Dict$fromList(
						$elm$core$List$concat(
							A2(
								$elm$core$List$map,
								function (region) {
									return parsecList(region);
								},
								regions)));
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{hexColours: hexColourDict, regionLabels: regionLabelDict, regions: regionDict})),
						$elm$core$Platform$Cmd$none);
				} else {
					var _v28 = msg.a;
					var requestEntry = _v28.a;
					var url = _v28.b;
					var err = msg.b.a;
					var stub = {
						colour: $avh4$elm_color$Color$blue,
						hexes: _List_fromArray(
							[
								{x: -308, y: -104},
								{x: -308, y: -105},
								{x: -307, y: -104},
								{x: -309, y: -104}
							]),
						id: 1,
						labelPosition: $elm$core$Maybe$Just(
							{x: -308, y: -104}),
						name: 'Stub Hennlix Nebula'
					};
					var regionLabelDict = $elm$core$Dict$fromList(
						A2(
							$elm$core$List$filterMap,
							function (region) {
								return A2(
									$elm$core$Maybe$map,
									function (pos) {
										return _Utils_Tuple2(
											$author$project$Traveller$HexAddress$toKey(pos),
											region.name);
									},
									region.labelPosition);
							},
							_List_fromArray(
								[stub])));
					var parsecList = function (region) {
						return A2(
							$elm$core$List$map,
							function (p) {
								return _Utils_Tuple2(
									$author$project$Traveller$HexAddress$toKey(p),
									region.colour);
							},
							region.hexes);
					};
					var hexColourDict = $elm$core$Dict$fromList(
						$elm$core$List$concat(
							A2(
								$elm$core$List$map,
								function (region) {
									return parsecList(region);
								},
								_List_fromArray(
									[stub]))));
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									hexColours: hexColourDict,
									regionLabels: regionLabelDict,
									regions: $elm$core$Dict$fromList(
										_List_fromArray(
											[
												_Utils_Tuple2(1, stub)
											]))
								})),
						$elm$core$Platform$Cmd$none);
				}
			case 'DownloadedRoute':
				if (msg.b.$ === 'Ok') {
					var _v29 = msg.a;
					var requestEntry = _v29.a;
					var url = _v29.b;
					var route = msg.b.a;
					var firstEntry = A2(
						$elm$core$Maybe$map,
						function ($) {
							return $.address;
						},
						$elm$core$List$head(
							$elm$core$List$reverse(route)));
					if (firstEntry.$ === 'Just') {
						var address = firstEntry.a;
						return _Utils_Tuple2(
							withTime(
								_Utils_update(
									model,
									{currentAddress: address, route: route})),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(
							withTime(
								_Utils_update(
									model,
									{route: route})),
							$elm$core$Platform$Cmd$none);
					}
				} else {
					var _v31 = msg.a;
					var requestEntry = _v31.a;
					var url = _v31.b;
					var err = msg.b.a;
					var _v32 = A2($elm$core$Debug$log, 'Route did not work', err);
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									newSolarSystemErrors: A2(
										$elm$core$List$cons,
										_Utils_Tuple2(err, url),
										model.newSolarSystemErrors)
								})),
						$elm$core$Platform$Cmd$none);
				}
			case 'FetchedSolarSystem':
				if (msg.a.$ === 'Ok') {
					var solarSystem = msg.a.a;
					var si = model.isReferee ? $author$project$Traveller$refereeSI : solarSystem.surveyIndex;
					var updatedSS = _Utils_update(
						solarSystem,
						{surveyIndex: si});
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									selectedSystem: $elm$core$Maybe$Just(updatedSS)
								})),
						$elm$core$Platform$Cmd$none);
				} else {
					if (msg.a.a.$ === 'BadBody') {
						var err = msg.a.a.a;
						return _Utils_Tuple2(
							withTime(
								_Utils_update(
									model,
									{
										newSolarSystemErrors: _Utils_ap(
											model.newSolarSystemErrors,
											_List_fromArray(
												[
													_Utils_Tuple2(
													$elm$http$Http$BadBody(err),
													'foo')
												]))
									})),
							$elm$core$Platform$Cmd$none);
					} else {
						var err = msg.a.a;
						var _v33 = A2($elm$core$Debug$log, '404', err);
						return _Utils_Tuple2(
							withTime(model),
							$elm$core$Platform$Cmd$none);
					}
				}
			case 'DownloadedSolarSystems':
				if (msg.b.$ === 'Ok') {
					var _v21 = msg.a;
					var requestEntry = _v21.a;
					var url_ = _v21.b;
					var fallibleSolarSystems = msg.b.a;
					var newRequestHistory = A3(
						$author$project$Traveller$markRequestComplete,
						requestEntry,
						$krisajenkins$remotedata$RemoteData$Success(_Utils_Tuple0),
						model.requestHistory);
					var existingDict = model.solarSystems;
					var _v22 = A2(
						$elm$core$Tuple$mapFirst,
						$elm$core$Dict$fromList,
						A3(
							$elm$core$List$foldl,
							F2(
								function (fallibleSystem, _v23) {
									var systems = _v23.a;
									var errs = _v23.b;
									var hasFailed = A2($elm$core$List$any, $elm_community$result_extra$Result$Extra$isErr, fallibleSystem.stars);
									if (!hasFailed) {
										var si = model.isReferee ? $author$project$Traveller$refereeSI : fallibleSystem.surveyIndex;
										var starSystem = {
											address: fallibleSystem.address,
											allegiance: fallibleSystem.allegiance,
											extinctSophont: fallibleSystem.extinctSophont,
											gasGiantCount: fallibleSystem.gasGiantCount,
											name: fallibleSystem.name,
											nativeSophont: fallibleSystem.nativeSophont,
											planetoidBeltCount: fallibleSystem.planetoidBeltCount,
											scanPoints: fallibleSystem.scanPoints,
											sectorName: fallibleSystem.sectorName,
											stars: A2(
												$elm$core$List$filterMap,
												$elm$core$Basics$identity,
												A2($elm$core$List$map, $elm$core$Result$toMaybe, fallibleSystem.stars)),
											surveyIndex: si,
											techLevel: fallibleSystem.techLevel,
											terrestrialPlanetCount: fallibleSystem.terrestrialPlanetCount
										};
										return _Utils_Tuple2(
											A2(
												$elm$core$List$cons,
												_Utils_Tuple2(
													$author$project$Traveller$HexAddress$toKey(fallibleSystem.address),
													$author$project$Traveller$LoadedSolarSystem(starSystem)),
												systems),
											errs);
									} else {
										return _Utils_Tuple2(
											A2(
												$elm$core$List$cons,
												_Utils_Tuple2(
													$author$project$Traveller$HexAddress$toKey(fallibleSystem.address),
													$author$project$Traveller$FailedStarsSolarSystem(
														A2($elm$core$Debug$log, 'failed', fallibleSystem))),
												systems),
											_Utils_ap(
												A2(
													$elm$core$List$map,
													function (er) {
														return _Utils_Tuple2(
															$elm$http$Http$BadBody(er),
															url_);
													},
													A2(
														$elm$core$List$filterMap,
														function (res) {
															if (res.$ === 'Ok') {
																return $elm$core$Maybe$Nothing;
															} else {
																var er = res.a;
																return $elm$core$Maybe$Just(
																	'Specific Star failed to decode:\n' + $elm$json$Json$Decode$errorToString(er));
															}
														},
														fallibleSystem.stars)),
												errs));
									}
								}),
							_Utils_Tuple2(_List_Nil, _List_Nil),
							fallibleSolarSystems));
					var sortedSolarSystems = _v22.a;
					var potentiallyNewErrors = _v22.b;
					var newErrors = A2(
						$elm$core$List$filter,
						function (_v25) {
							var newErr = _v25.a;
							var errUrl = _v25.b;
							return !A2(
								$elm$core$List$member,
								newErr,
								A2($elm$core$List$map, $elm$core$Tuple$first, model.oldSolarSystemErrors));
						},
						potentiallyNewErrors);
					var rangeAsPairs = A2(
						$elm$core$List$map,
						function (addr) {
							var addrKey = $author$project$Traveller$HexAddress$toKey(addr);
							return _Utils_Tuple2(
								addrKey,
								A2(
									$elm$core$Maybe$withDefault,
									$author$project$Traveller$LoadedEmptyHex,
									A2($elm$core$Dict$get, addrKey, sortedSolarSystems)));
						},
						A2($author$project$Traveller$HexAddress$between, requestEntry.upperLeftHex, requestEntry.lowerRightHex));
					var solarSystemDict = function (newDict) {
						return A2($elm$core$Dict$union, newDict, existingDict);
					}(
						$elm$core$Dict$fromList(rangeAsPairs));
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									newSolarSystemErrors: _Utils_ap(newErrors, model.newSolarSystemErrors),
									requestHistory: newRequestHistory,
									solarSystems: solarSystemDict
								})),
						$elm$core$Platform$Cmd$batch(
							_List_fromArray(
								[
									A2(
									$elm$core$Task$attempt,
									$author$project$Traveller$GotHexMapViewport,
									$elm$browser$Browser$Dom$getViewportOf('hexmap'))
								])));
				} else {
					var _v34 = msg.a;
					var requestEntry = _v34.a;
					var url = _v34.b;
					var err = msg.b.a;
					var newRequestHistory = A3(
						$author$project$Traveller$markRequestComplete,
						requestEntry,
						$krisajenkins$remotedata$RemoteData$Failure(err),
						model.requestHistory);
					var existingDict = model.solarSystems;
					var rangeAsPairs = A2(
						$elm$core$List$map,
						function (addr) {
							var addrKey = $author$project$Traveller$HexAddress$toKey(addr);
							return _Utils_Tuple2(
								addrKey,
								function (maybeSolarsystem) {
									if (maybeSolarsystem.$ === 'Just') {
										switch (maybeSolarsystem.a.$) {
											case 'LoadingSolarSystem':
												var _v36 = maybeSolarsystem.a;
												return $author$project$Traveller$FailedSolarSystem(err);
											case 'LoadedEmptyHex':
												var _v37 = maybeSolarsystem.a;
												return $author$project$Traveller$FailedSolarSystem(err);
											case 'FailedSolarSystem':
												return $author$project$Traveller$FailedSolarSystem(err);
											case 'LoadedSolarSystem':
												var solarSystem = maybeSolarsystem.a.a;
												return $author$project$Traveller$LoadedSolarSystem(solarSystem);
											default:
												return $author$project$Traveller$FailedSolarSystem(err);
										}
									} else {
										return $author$project$Traveller$FailedSolarSystem(err);
									}
								}(
									A2($elm$core$Dict$get, addrKey, existingDict)));
						},
						A2($author$project$Traveller$HexAddress$between, requestEntry.upperLeftHex, requestEntry.lowerRightHex));
					var solarSystemDict = function (newDict) {
						return A2($elm$core$Dict$union, newDict, existingDict);
					}(
						$elm$core$Dict$fromList(rangeAsPairs));
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{
									lastSolarSystemError: $elm$core$Maybe$Just(err),
									newSolarSystemErrors: A2(
										$elm$core$List$cons,
										_Utils_Tuple2(err, url),
										model.newSolarSystemErrors),
									requestHistory: newRequestHistory,
									solarSystems: solarSystemDict
								})),
						$elm$core$Platform$Cmd$none);
				}
			case 'HoveringHex':
				var hoveringHex = msg.a;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								hoveringHex: $elm$core$Maybe$Just(hoveringHex)
							})),
					$elm$core$Platform$Cmd$none);
			case 'GotViewport':
				var viewport = msg.a;
				var oldViewport = model.viewport;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								viewport: _Utils_update(
									oldViewport,
									{viewport: viewport})
							})),
					A2(
						$elm$core$Task$attempt,
						$author$project$Traveller$GotHexMapViewport,
						$elm$browser$Browser$Dom$getViewportOf('hexmap')));
			case 'GotHexMapViewport':
				var hexmapOrErr = msg.a;
				var oldViewport = model.viewport;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								viewport: _Utils_update(
									oldViewport,
									{
										hexmapViewport: $elm$core$Maybe$Just(hexmapOrErr)
									})
							})),
					$elm$core$Platform$Cmd$none);
			case 'GotResize':
				var width = msg.a;
				var height = msg.b;
				return _Utils_Tuple2(
					withTime(model),
					$elm$core$Platform$Cmd$batch(
						_List_fromArray(
							[
								A2($elm$core$Task$perform, $author$project$Traveller$GotViewport, $elm$browser$Browser$Dom$getViewport),
								A2(
								$elm$core$Task$attempt,
								$author$project$Traveller$GotHexMapViewport,
								$elm$browser$Browser$Dom$getViewportOf('hexmap'))
							])));
			case 'ViewingHex':
				var hexAddress = msg.a;
				var focusedErrors = A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					A2(
						$elm$core$Maybe$map,
						function (system) {
							if (system.$ === 'FailedStarsSolarSystem') {
								var fallibleSystem = system.a;
								return A2(
									$elm$core$List$map,
									function (er) {
										return _Utils_Tuple2(
											$elm$http$Http$BadBody(er),
											'TODO: tie RequestEntry to URL');
									},
									A2(
										$elm$core$List$filterMap,
										function (res) {
											if (res.$ === 'Ok') {
												return $elm$core$Maybe$Nothing;
											} else {
												var er = res.a;
												return $elm$core$Maybe$Just(
													'Specific Star failed to decode:\n' + $elm$json$Json$Decode$errorToString(er));
											}
										},
										fallibleSystem.stars));
							} else {
								return _List_Nil;
							}
						},
						A2(
							$elm$core$Dict$get,
							$author$project$Traveller$HexAddress$toKey(hexAddress),
							model.solarSystems)));
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								newSolarSystemErrors: focusedErrors,
								selectedHex: $elm$core$Maybe$Just(hexAddress),
								selectedStellarObject: $elm$core$Maybe$Nothing,
								selectedSystem: $elm$core$Maybe$Nothing
							})),
					A2(
						$author$project$Traveller$fetchSingleSolarSystemRequest,
						model.hostConfig,
						$author$project$Traveller$HexAddress$toSectorAddress(hexAddress)));
			case 'FocusInSidebar':
				var stellarObject = msg.a;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								selectedStellarObject: $elm$core$Maybe$Just(stellarObject)
							})),
					$elm$core$Platform$Cmd$none);
			case 'MapMouseDown':
				var coordinates = msg.a;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								dragMode: $author$project$Traveller$IsDragging(
									{last: coordinates, start: coordinates})
							})),
					$elm$core$Platform$Cmd$none);
			case 'MapMouseUp':
				var _v40 = model.dragMode;
				if (_v40.$ === 'IsDragging') {
					var start = _v40.a.start;
					var last = _v40.a.last;
					if (!_Utils_eq(start, last)) {
						var _v41 = A2(
							$author$project$Traveller$prepNextRequest,
							_Utils_Tuple2(model.solarSystems, model.requestHistory),
							model.hexRect);
						var nextRequestEntry = _v41.a;
						var _v42 = _v41.b;
						var newSolarSystemDict = _v42.a;
						var newRequestHistory = _v42.b;
						return _Utils_Tuple2(
							withTime(
								_Utils_update(
									model,
									{dragMode: $author$project$Traveller$NoDragging, requestHistory: newRequestHistory, solarSystems: newSolarSystemDict})),
							A3($author$project$Traveller$sendSolarSystemRequest, nextRequestEntry, model.hostConfig, model.hexRect));
					} else {
						return _Utils_Tuple2(
							withTime(
								_Utils_update(
									model,
									{dragMode: $author$project$Traveller$NoDragging})),
							$elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(
						withTime(
							_Utils_update(
								model,
								{dragMode: $author$project$Traveller$NoDragging})),
						$elm$core$Platform$Cmd$none);
				}
			case 'MapMouseMove':
				var _v43 = msg.a;
				var newX = _v43.a;
				var newY = _v43.b;
				var _v44 = model.dragMode;
				if (_v44.$ === 'IsDragging') {
					var start = _v44.a.start;
					var last = _v44.a.last;
					var _v45 = last;
					var originX = _v45.a;
					var originY = _v45.b;
					var xDelta = ((originX - newX) / model.hexScale) | 0;
					var yDelta = ((originY - newY) / model.hexScale) | 0;
					var shiftAddress = function (hex) {
						return A2(
							$author$project$Traveller$HexAddress$shiftAddressBy,
							{deltaX: xDelta, deltaY: yDelta},
							hex);
					};
					var newHexRect = {
						lowerRightHex: shiftAddress(model.hexRect.lowerRightHex),
						upperLeftHex: shiftAddress(model.hexRect.upperLeftHex)
					};
					var newModel = _Utils_update(
						model,
						{
							dragMode: $author$project$Traveller$IsDragging(
								{
									last: _Utils_Tuple2(newX, newY),
									start: start
								}),
							hexRect: newHexRect
						});
					return ((!(!xDelta)) || (!(!yDelta))) ? _Utils_Tuple2(
						withTime(newModel),
						$author$project$Traveller$saveMapCoords(newModel.hexRect.upperLeftHex)) : _Utils_Tuple2(
						withTime(model),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(
						withTime(model),
						$elm$core$Platform$Cmd$none);
				}
			case 'MapMouseLeave':
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{hoveringHex: $elm$core$Maybe$Nothing})),
					$elm$core$Platform$Cmd$none);
			case 'ClearAllErrors':
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								newSolarSystemErrors: _List_Nil,
								oldSolarSystemErrors: _Utils_ap(model.newSolarSystemErrors, model.oldSolarSystemErrors)
							})),
					$elm$core$Platform$Cmd$none);
			case 'JumpToShip':
				return A2(
					$author$project$Traveller$update,
					A2($author$project$Traveller$ZoomToHex, model.currentAddress, true),
					withTime(model));
			case 'ZoomToHex':
				var hexAddress = msg.a;
				var centre = msg.b;
				var extraPadding = 2;
				var hHexes = A2($author$project$Traveller$horizontalHexes, model.viewport.hexmapViewport, model.hexScale) + extraPadding;
				var vHexes = A2($author$project$Traveller$verticalHexes, model.viewport.hexmapViewport, model.hexScale) + extraPadding;
				var newUpperLeft = centre ? A2(
					$author$project$Traveller$HexAddress$shiftAddressBy,
					{deltaX: (((-1) * hHexes) / 2) | 0, deltaY: (((-1) * vHexes) / 2) | 0},
					hexAddress) : A2(
					$author$project$Traveller$HexAddress$shiftAddressBy,
					{deltaX: -2, deltaY: -2},
					hexAddress);
				var newHexRect = {
					lowerRightHex: A2(
						$author$project$Traveller$HexAddress$shiftAddressBy,
						{deltaX: hHexes, deltaY: vHexes},
						newUpperLeft),
					upperLeftHex: newUpperLeft
				};
				var _v46 = A2(
					$author$project$Traveller$prepNextRequest,
					_Utils_Tuple2(model.solarSystems, model.requestHistory),
					newHexRect);
				var nextRequestEntry = _v46.a;
				var _v47 = _v46.b;
				var newSolarSystemDict = _v47.a;
				var newRequestHistory = _v47.b;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{hexRect: newHexRect, requestHistory: newRequestHistory, solarSystems: newSolarSystemDict})),
					$elm$core$Platform$Cmd$batch(
						_List_fromArray(
							[
								$author$project$Traveller$saveMapCoords(newHexRect.upperLeftHex),
								A3($author$project$Traveller$sendSolarSystemRequest, nextRequestEntry, model.hostConfig, newHexRect)
							])));
			case 'ToggleHexmap':
				var newViewMode = _Utils_eq(model.viewMode, $author$project$Traveller$HexMap) ? $author$project$Traveller$FullJourney : $author$project$Traveller$HexMap;
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{viewMode: newViewMode})),
					$elm$core$Platform$Cmd$none);
			case 'JourneyMsg':
				var journeyMsg = msg.a;
				return A2(
					$author$project$Traveller$updateJourney,
					journeyMsg,
					withTime(model));
			case 'ViewObjectAnalysisDetail':
				var stellarObject = msg.a;
				var rndm = F2(
					function (digits, def) {
						return A2(
							$elm$core$Basics$composeR,
							$elm$core$Maybe$withDefault(def),
							$myrho$elm_round$Round$round(digits));
					});
				var rnd = function (digits) {
					return $myrho$elm_round$Round$round(digits);
				};
				var fromKelvin = function (k) {
					return A2(
						rnd,
						0,
						A2($elm$core$Maybe$withDefault, 0, k) - 273.15);
				};
				var analysisDetail = function () {
					var header = {
						header: $author$project$Traveller$StellarObject$getStellarOrbit(stellarObject).orbitSequence + (' [' + ($author$project$Traveller$StellarObject$getProfileString(stellarObject) + ']'))
					};
					var buildStringPlanetoidBelt = function (pdata) {
						return {
							physical: {
								au: A2(rnd, 2, pdata.au),
								bulk: A2(rnd, 0, pdata.bulk),
								cType: A2(rnd, 0, pdata.cType) + '%',
								eccentricity: A2(rnd, 2, pdata.eccentricity),
								inclination: A2(rnd, 0, pdata.inclination) + '°',
								mType: A2(rnd, 0, pdata.mType) + '%',
								oType: A2(rnd, 0, pdata.oType) + '%',
								period: A2(rnd, 2, pdata.period / 365.25),
								sType: A2(rnd, 0, pdata.sType) + '%',
								span: A2(rnd, 0, pdata.span)
							}
						};
					};
					var buildStringPlanet = function (pdata) {
						return {
							atmosphere: {
								bar: A2(rnd, 1, pdata.atmosphere.bar),
								hazardCode: $author$project$Traveller$Atmosphere$atmosphereHazardDescription(pdata.atmosphere.hazardCode),
								taint: {
									persistence: $author$project$Traveller$StellarTaint$taintPersistenceDescription(pdata.atmosphere.taint.persistence),
									severity: $author$project$Traveller$StellarTaint$taintSeverityDescription(pdata.atmosphere.taint.severity),
									subtype: $author$project$Traveller$StellarTaint$taintSubtypeDescription(pdata.atmosphere.taint.code)
								},
								type_: $author$project$Traveller$Atmosphere$atmosphereDescriptionEx(pdata.atmosphere.code)
							},
							hydrographics: {
								percentage: A2(
									$elm$core$Maybe$withDefault,
									'N/A',
									A2(
										$elm$core$Maybe$map,
										A2(
											$elm$core$Basics$composeR,
											function ($) {
												return $.code;
											},
											$author$project$Traveller$Hydrographics$hydrographicsPercentageDescription),
										pdata.hydrographics)),
								surfaceDistribution: A2(
									$elm$core$Maybe$withDefault,
									'N/A',
									A2(
										$elm$core$Maybe$map,
										A2(
											$elm$core$Basics$composeR,
											function ($) {
												return $.distribution;
											},
											$author$project$Traveller$Hydrographics$surfaceDistributionDescription),
										pdata.hydrographics))
							},
							life: {
								biocomplexity: $author$project$Traveller$Lifeforms$biocomplexityDescription(pdata.biocomplexityCode),
								biodiversity: $author$project$Traveller$Lifeforms$biodiversityDescription(pdata.biodiversityRating),
								biomass: $author$project$Traveller$Lifeforms$biomassDescription(pdata.biomassRating),
								compatibility: $author$project$Traveller$Lifeforms$bioChemistryCompatibilityDescription(pdata.compatibilityRating),
								habitability: $author$project$Traveller$Lifeforms$habitabilityDescription(pdata.habitabilityRating),
								sophonts: pdata.nativeSophont ? 'Yes' : 'No'
							},
							physical: {
								albedo: A2(rnd, 2, pdata.albedo),
								au: A2(rnd, 2, pdata.au),
								axialTilt: A2(rnd, 2, pdata.axialTilt) + '°',
								density: A3(rndm, 2, 0, pdata.density),
								diameter: A2(rnd, 0, pdata.diameter),
								eccentricity: A2(rnd, 2, pdata.eccentricity),
								gravity: A3(rndm, 2, 0, pdata.gravity),
								greenhouse: A3(rndm, 2, 0, pdata.greenhouse),
								inclination: A2(rnd, 0, pdata.inclination) + '°',
								mass: A3(rndm, 2, 0, pdata.mass),
								meanTemperature: fromKelvin(pdata.meanTemperature),
								period: A2(rnd, 2, pdata.period / 365.25)
							}
						};
					};
					var buildStringGasGiant = function (ggdata) {
						return {
							physical: {
								au: A2(rnd, 2, ggdata.au),
								axialTilt: A2(rnd, 2, ggdata.axialTilt) + '°',
								diameter: A2(
									$cuducos$elm_format_number$FormatNumber$format,
									_Utils_update(
										$cuducos$elm_format_number$FormatNumber$Locales$usLocale,
										{
											decimals: $cuducos$elm_format_number$FormatNumber$Locales$Exact(0),
											thousandSeparator: ' '
										}),
									ggdata.diameter),
								eccentricity: A2(rnd, 2, ggdata.eccentricity),
								hasRing: ggdata.hasRing ? 'Yes' : 'No',
								inclination: A2(rnd, 0, ggdata.inclination) + '°',
								mass: A3(rndm, 2, 0, ggdata.mass),
								moons: $elm$core$String$fromInt(
									$elm$core$List$length(ggdata.moons)),
								period: A2(rnd, 2, ggdata.period / 365.25)
							}
						};
					};
					switch (stellarObject.$) {
						case 'GasGiant':
							var gasGiantData = stellarObject.a;
							return A2(
								$author$project$Traveller$AnalysisDetail$AnalyisDetailGasGiant,
								header,
								buildStringGasGiant(gasGiantData));
						case 'TerrestrialPlanet':
							var pdata = stellarObject.a;
							return A2(
								$author$project$Traveller$AnalysisDetail$AnalyisDetailPlanetoid,
								header,
								buildStringPlanet(pdata));
						case 'PlanetoidBelt':
							var planetoidBeltData = stellarObject.a;
							return A2(
								$author$project$Traveller$AnalysisDetail$AnalyisDetailPlanetoidBelt,
								header,
								buildStringPlanetoidBelt(planetoidBeltData));
						case 'Planetoid':
							var pdata = stellarObject.a;
							return A2(
								$author$project$Traveller$AnalysisDetail$AnalyisDetailPlanetoid,
								header,
								buildStringPlanet(pdata));
						default:
							var starDataConfig = stellarObject.a.a;
							return $author$project$Traveller$AnalysisDetail$AnalyisDetailStar;
					}
				}();
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{
								objectToBeAnalyzed: $elm$core$Maybe$Just(
									{data: analysisDetail, stellarObject: stellarObject})
							})),
					A2($elm$core$Task$perform, $author$project$Traveller$OpenedObjectAnalysisTime, $elm$time$Time$now));
			case 'OpenedObjectAnalysisTime':
				var openedTime = msg.a;
				var _v49 = A2($elm$core$Debug$log, 'got time', 123);
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{timeOpened: openedTime})),
					$elm$core$Platform$Cmd$none);
			default:
				return _Utils_Tuple2(
					withTime(
						_Utils_update(
							model,
							{objectToBeAnalyzed: $elm$core$Maybe$Nothing})),
					$elm$core$Platform$Cmd$none);
		}
	});
var $author$project$Traveller$updateJourney = F2(
	function (journeyMsg, _v0) {
		var time = _v0.a;
		var model = _v0.b;
		var journeyModel = model.journeyModel;
		var setJourneyModel = function (newJourneyModel) {
			return _Utils_Tuple2(
				time,
				_Utils_update(
					model,
					{journeyModel: newJourneyModel}));
		};
		switch (journeyMsg.$) {
			case 'Zoom':
				var zoomType = journeyMsg.a;
				var newZoomScale = function () {
					switch (zoomType.$) {
						case 'ZoomIn':
							return journeyModel.zoomScale * 1.5;
						case 'ZoomOut':
							return journeyModel.zoomScale / 1.5;
						default:
							var newZoom = zoomType.a;
							return newZoom;
					}
				}();
				var newJourneyModel = _Utils_update(
					journeyModel,
					{
						zoomScale: A2($elm$core$Debug$log, 'new zoom', newZoomScale)
					});
				return _Utils_Tuple2(
					setJourneyModel(newJourneyModel),
					$elm$core$Platform$Cmd$none);
			case 'MouseDown':
				var originalPos = journeyMsg.a;
				return _Utils_Tuple2(
					setJourneyModel(
						_Utils_update(
							journeyModel,
							{
								dragMode: $author$project$Traveller$IsDragging(
									{last: originalPos, start: originalPos})
							})),
					$elm$core$Platform$Cmd$none);
			case 'MouseLeave':
				return _Utils_Tuple2(
					setJourneyModel(
						_Utils_update(
							journeyModel,
							{dragMode: $author$project$Traveller$NoDragging, hoverPoint: $elm$core$Maybe$Nothing})),
					$elm$core$Platform$Cmd$none);
			case 'MouseMove':
				var _v3 = journeyMsg.a;
				var newX = _v3.a;
				var newY = _v3.b;
				var _v4 = journeyModel.dragMode;
				if (_v4.$ === 'IsDragging') {
					var start = _v4.a.start;
					var last = _v4.a.last;
					var _v5 = last;
					var originalX = _v5.a;
					var originalY = _v5.b;
					var _v6 = _Utils_Tuple2(newX - originalX, newY - originalY);
					var xDelta = _v6.a;
					var yDelta = _v6.b;
					var _v7 = journeyModel.zoomOffset;
					var oldX = _v7.a;
					var oldY = _v7.b;
					var _v8 = _Utils_Tuple2((model.viewport.viewport.viewport.width - $author$project$Traveller$Sidebar$sidebarWidth) - 50, model.viewport.viewport.viewport.height);
					var maxWidth = _v8.a;
					var maxHeight = _v8.b;
					var _v9 = _Utils_Tuple2(maxWidth * journeyModel.zoomScale, maxHeight * journeyModel.zoomScale);
					var curImgWidth = _v9.a;
					var curImgHeight = _v9.b;
					var newModel = _Utils_update(
						journeyModel,
						{
							dragMode: $author$project$Traveller$IsDragging(
								{
									last: _Utils_Tuple2(newX, newY),
									start: start
								}),
							hoverPoint: $elm$core$Maybe$Nothing,
							zoomOffset: _Utils_Tuple2(
								A3($elm$core$Basics$clamp, maxWidth - curImgWidth, 0, oldX + xDelta),
								A3($elm$core$Basics$clamp, maxHeight - curImgHeight, 0, oldY + yDelta))
						});
					return ((!(!xDelta)) || (!(!yDelta))) ? _Utils_Tuple2(
						setJourneyModel(newModel),
						$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
						setJourneyModel(
							_Utils_update(
								journeyModel,
								{hoverPoint: $elm$core$Maybe$Nothing})),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(
						setJourneyModel(
							_Utils_update(
								journeyModel,
								{
									hoverPoint: $elm$core$Maybe$Just(
										_Utils_Tuple2(newX, newY))
								})),
						$elm$core$Platform$Cmd$none);
				}
			default:
				var coordinates = journeyMsg.a;
				var _v10 = journeyModel.dragMode;
				if (_v10.$ === 'IsDragging') {
					var start = _v10.a.start;
					var hexViewToSector = function (arg1) {
						var vh = A2($author$project$Traveller$verticalHexes, model.viewport.hexmapViewport, model.hexScale) + 3;
						var newJourneyModel = _Utils_update(
							journeyModel,
							{dragMode: $author$project$Traveller$NoDragging});
						var hh = A2($author$project$Traveller$horizontalHexes, model.viewport.hexmapViewport, model.hexScale) + 2;
						var _v14 = function () {
							var scaledWidth = (model.viewport.viewport.viewport.width - $author$project$Traveller$Sidebar$sidebarWidth) - 50;
							return _Utils_Tuple2(scaledWidth, scaledWidth * ($author$project$Traveller$fullJourneyImageHeight / $author$project$Traveller$fullJourneyImageWidth));
						}();
						var maxWidth = _v14.a;
						var maxHeight = _v14.b;
						var imageSize = {height: maxHeight * journeyModel.zoomScale, width: maxWidth * journeyModel.zoomScale};
						var sector = A3(
							$author$project$Traveller$mouseCoordsToSector,
							$author$project$Traveller$toXY(coordinates),
							$author$project$Traveller$toXY(journeyModel.zoomOffset),
							imageSize);
						var hexAddress = A2(
							$author$project$Traveller$HexAddress$shiftAddressBy,
							{deltaX: -2, deltaY: -2},
							$author$project$Traveller$HexAddress$createFromStarSystem(
								{sectorX: sector.x, sectorY: sector.y, x: 1, y: 1}));
						var newHexRect = {
							lowerRightHex: A2(
								$author$project$Traveller$HexAddress$shiftAddressBy,
								{deltaX: hh, deltaY: vh},
								hexAddress),
							upperLeftHex: hexAddress
						};
						var newModel = _Utils_update(
							model,
							{dragMode: $author$project$Traveller$NoDragging, hexRect: newHexRect, journeyModel: newJourneyModel, viewMode: $author$project$Traveller$HexMap});
						return A2(
							$author$project$Traveller$update,
							$author$project$Traveller$DownloadSolarSystems,
							_Utils_Tuple2(time, newModel));
					};
					var _v11 = start;
					var ox = _v11.a;
					var oy = _v11.b;
					var _v12 = coordinates;
					var cx = _v12.a;
					var cy = _v12.b;
					var dist = $elm$core$Basics$sqrt(
						A2($elm$core$Basics$pow, cx - ox, 2) + A2($elm$core$Basics$pow, cy - oy, 2));
					var _v13 = A2($elm$core$Debug$log, 'mouse up', 123);
					return (dist > 2) ? _Utils_Tuple2(
						setJourneyModel(
							_Utils_update(
								journeyModel,
								{dragMode: $author$project$Traveller$NoDragging})),
						$elm$core$Platform$Cmd$none) : hexViewToSector(_Utils_Tuple0);
				} else {
					return _Utils_Tuple2(
						_Utils_Tuple2(time, model),
						$elm$core$Platform$Cmd$none);
				}
		}
	});
var $author$project$Main$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 'NoOp':
				return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			case 'LinkClicked':
				var urlRequest = msg.a;
				if (urlRequest.$ === 'Internal') {
					var url = urlRequest.a;
					return _Utils_Tuple2(
						model,
						A2(
							$elm$browser$Browser$Navigation$pushUrl,
							model.key,
							$elm$url$Url$toString(url)));
				} else {
					var href = urlRequest.a;
					return _Utils_Tuple2(
						model,
						$elm$browser$Browser$Navigation$load(href));
				}
			case 'UrlChanged':
				var url = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							route: A2($elm$url$Url$Parser$parse, $author$project$Main$routeParser, url),
							url: url
						}),
					$elm$core$Platform$Cmd$none);
			case 'ToggleErrorDialog':
				return _Utils_Tuple2(
					model,
					$author$project$Main$toggleDialog('error-dialog'));
			case 'GotTravellerMsg':
				var travellerMsg = msg.a;
				var _v2 = model.travellerModel;
				if (_v2.$ === 'Just') {
					var tm = _v2.a;
					var _v3 = A2($author$project$Traveller$update, travellerMsg, tm);
					var newTravellerModel = _v3.a;
					var newTravellerCmds = _v3.b;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								travellerModel: $elm$core$Maybe$Just(newTravellerModel)
							}),
						A2($elm$core$Platform$Cmd$map, $author$project$Main$GotTravellerMsg, newTravellerCmds));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			default:
				var viewport = msg.a;
				var _v4 = model.travellerModel;
				if (_v4.$ === 'Just') {
					var tm = _v4.a;
					var _v5 = A2(
						$author$project$Traveller$update,
						$author$project$Traveller$GotViewport(viewport),
						tm);
					var newTraveller = _v5.a;
					var cmd = _v5.b;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								travellerModel: $elm$core$Maybe$Just(newTraveller)
							}),
						A2($elm$core$Platform$Cmd$map, $author$project$Main$GotTravellerMsg, cmd));
				} else {
					var _v6 = A5(
						$author$project$Traveller$init,
						viewport,
						{campaignName: model.flags.campaignName, hexSize: model.flags.hexSize, shipName: model.flags.shipName, upperLeft: model.flags.upperLeft},
						model.key,
						model.hostConfig,
						model.referee);
					var newTraveller = _v6.a;
					var cmd = _v6.b;
					var newModel = _Utils_update(
						model,
						{
							travellerModel: $elm$core$Maybe$Just(newTraveller)
						});
					return _Utils_Tuple2(
						newModel,
						A2($elm$core$Platform$Cmd$map, $author$project$Main$GotTravellerMsg, cmd));
				}
		}
	});
var $author$project$Main$ToggleErrorDialog = {$: 'ToggleErrorDialog'};
var $mdgriffith$elm_ui$Internal$Model$AlignX = function (a) {
	return {$: 'AlignX', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$CenterX = {$: 'CenterX'};
var $mdgriffith$elm_ui$Element$centerX = $mdgriffith$elm_ui$Internal$Model$AlignX($mdgriffith$elm_ui$Internal$Model$CenterX);
var $elm$html$Html$div = _VirtualDom_node('div');
var $mdgriffith$elm_ui$Internal$Model$FocusStyleOption = function (a) {
	return {$: 'FocusStyleOption', a: a};
};
var $mdgriffith$elm_ui$Element$focusStyle = $mdgriffith$elm_ui$Internal$Model$FocusStyleOption;
var $mdgriffith$elm_ui$Internal$Model$Attr = function (a) {
	return {$: 'Attr', a: a};
};
var $mdgriffith$elm_ui$Element$htmlAttribute = $mdgriffith$elm_ui$Internal$Model$Attr;
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $mdgriffith$elm_ui$Internal$Style$classes = {above: 'a', active: 'atv', alignBottom: 'ab', alignCenterX: 'cx', alignCenterY: 'cy', alignContainerBottom: 'acb', alignContainerCenterX: 'accx', alignContainerCenterY: 'accy', alignContainerRight: 'acr', alignLeft: 'al', alignRight: 'ar', alignTop: 'at', alignedHorizontally: 'ah', alignedVertically: 'av', any: 's', behind: 'bh', below: 'b', bold: 'w7', borderDashed: 'bd', borderDotted: 'bdt', borderNone: 'bn', borderSolid: 'bs', capturePointerEvents: 'cpe', clip: 'cp', clipX: 'cpx', clipY: 'cpy', column: 'c', container: 'ctr', contentBottom: 'cb', contentCenterX: 'ccx', contentCenterY: 'ccy', contentLeft: 'cl', contentRight: 'cr', contentTop: 'ct', cursorPointer: 'cptr', cursorText: 'ctxt', focus: 'fcs', focusedWithin: 'focus-within', fullSize: 'fs', grid: 'g', hasBehind: 'hbh', heightContent: 'hc', heightExact: 'he', heightFill: 'hf', heightFillPortion: 'hfp', hover: 'hv', imageContainer: 'ic', inFront: 'fr', inputLabel: 'lbl', inputMultiline: 'iml', inputMultilineFiller: 'imlf', inputMultilineParent: 'imlp', inputMultilineWrapper: 'implw', inputText: 'it', italic: 'i', link: 'lnk', nearby: 'nb', noTextSelection: 'notxt', onLeft: 'ol', onRight: 'or', opaque: 'oq', overflowHidden: 'oh', page: 'pg', paragraph: 'p', passPointerEvents: 'ppe', root: 'ui', row: 'r', scrollbars: 'sb', scrollbarsX: 'sbx', scrollbarsY: 'sby', seButton: 'sbt', single: 'e', sizeByCapital: 'cap', spaceEvenly: 'sev', strike: 'sk', text: 't', textCenter: 'tc', textExtraBold: 'w8', textExtraLight: 'w2', textHeavy: 'w9', textJustify: 'tj', textJustifyAll: 'tja', textLeft: 'tl', textLight: 'w3', textMedium: 'w5', textNormalWeight: 'w4', textRight: 'tr', textSemiBold: 'w6', textThin: 'w1', textUnitalicized: 'tun', transition: 'ts', transparent: 'clr', underline: 'u', widthContent: 'wc', widthExact: 'we', widthFill: 'wf', widthFillPortion: 'wfp', wrapped: 'wrp'};
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $mdgriffith$elm_ui$Internal$Model$htmlClass = function (cls) {
	return $mdgriffith$elm_ui$Internal$Model$Attr(
		$elm$html$Html$Attributes$class(cls));
};
var $mdgriffith$elm_ui$Internal$Model$OnlyDynamic = F2(
	function (a, b) {
		return {$: 'OnlyDynamic', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$StaticRootAndDynamic = F2(
	function (a, b) {
		return {$: 'StaticRootAndDynamic', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Unkeyed = function (a) {
	return {$: 'Unkeyed', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$AsEl = {$: 'AsEl'};
var $mdgriffith$elm_ui$Internal$Model$asEl = $mdgriffith$elm_ui$Internal$Model$AsEl;
var $mdgriffith$elm_ui$Internal$Model$Generic = {$: 'Generic'};
var $mdgriffith$elm_ui$Internal$Model$div = $mdgriffith$elm_ui$Internal$Model$Generic;
var $mdgriffith$elm_ui$Internal$Model$NoNearbyChildren = {$: 'NoNearbyChildren'};
var $mdgriffith$elm_ui$Internal$Model$columnClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.column);
var $mdgriffith$elm_ui$Internal$Model$gridClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.grid);
var $mdgriffith$elm_ui$Internal$Model$pageClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.page);
var $mdgriffith$elm_ui$Internal$Model$paragraphClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.paragraph);
var $mdgriffith$elm_ui$Internal$Model$rowClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.row);
var $mdgriffith$elm_ui$Internal$Model$singleClass = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.single);
var $mdgriffith$elm_ui$Internal$Model$contextClasses = function (context) {
	switch (context.$) {
		case 'AsRow':
			return $mdgriffith$elm_ui$Internal$Model$rowClass;
		case 'AsColumn':
			return $mdgriffith$elm_ui$Internal$Model$columnClass;
		case 'AsEl':
			return $mdgriffith$elm_ui$Internal$Model$singleClass;
		case 'AsGrid':
			return $mdgriffith$elm_ui$Internal$Model$gridClass;
		case 'AsParagraph':
			return $mdgriffith$elm_ui$Internal$Model$paragraphClass;
		default:
			return $mdgriffith$elm_ui$Internal$Model$pageClass;
	}
};
var $mdgriffith$elm_ui$Internal$Model$Keyed = function (a) {
	return {$: 'Keyed', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$NoStyleSheet = {$: 'NoStyleSheet'};
var $mdgriffith$elm_ui$Internal$Model$Styled = function (a) {
	return {$: 'Styled', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$Unstyled = function (a) {
	return {$: 'Unstyled', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$addChildren = F2(
	function (existing, nearbyChildren) {
		switch (nearbyChildren.$) {
			case 'NoNearbyChildren':
				return existing;
			case 'ChildrenBehind':
				var behind = nearbyChildren.a;
				return _Utils_ap(behind, existing);
			case 'ChildrenInFront':
				var inFront = nearbyChildren.a;
				return _Utils_ap(existing, inFront);
			default:
				var behind = nearbyChildren.a;
				var inFront = nearbyChildren.b;
				return _Utils_ap(
					behind,
					_Utils_ap(existing, inFront));
		}
	});
var $mdgriffith$elm_ui$Internal$Model$addKeyedChildren = F3(
	function (key, existing, nearbyChildren) {
		switch (nearbyChildren.$) {
			case 'NoNearbyChildren':
				return existing;
			case 'ChildrenBehind':
				var behind = nearbyChildren.a;
				return _Utils_ap(
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						behind),
					existing);
			case 'ChildrenInFront':
				var inFront = nearbyChildren.a;
				return _Utils_ap(
					existing,
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						inFront));
			default:
				var behind = nearbyChildren.a;
				var inFront = nearbyChildren.b;
				return _Utils_ap(
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						behind),
					_Utils_ap(
						existing,
						A2(
							$elm$core$List$map,
							function (x) {
								return _Utils_Tuple2(key, x);
							},
							inFront)));
		}
	});
var $mdgriffith$elm_ui$Internal$Model$AsParagraph = {$: 'AsParagraph'};
var $mdgriffith$elm_ui$Internal$Model$asParagraph = $mdgriffith$elm_ui$Internal$Model$AsParagraph;
var $mdgriffith$elm_ui$Internal$Flag$Flag = function (a) {
	return {$: 'Flag', a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$Second = function (a) {
	return {$: 'Second', a: a};
};
var $elm$core$Bitwise$shiftLeftBy = _Bitwise_shiftLeftBy;
var $mdgriffith$elm_ui$Internal$Flag$flag = function (i) {
	return (i > 31) ? $mdgriffith$elm_ui$Internal$Flag$Second(1 << (i - 32)) : $mdgriffith$elm_ui$Internal$Flag$Flag(1 << i);
};
var $mdgriffith$elm_ui$Internal$Flag$alignBottom = $mdgriffith$elm_ui$Internal$Flag$flag(41);
var $mdgriffith$elm_ui$Internal$Flag$alignRight = $mdgriffith$elm_ui$Internal$Flag$flag(40);
var $mdgriffith$elm_ui$Internal$Flag$centerX = $mdgriffith$elm_ui$Internal$Flag$flag(42);
var $mdgriffith$elm_ui$Internal$Flag$centerY = $mdgriffith$elm_ui$Internal$Flag$flag(43);
var $elm$core$Set$Set_elm_builtin = function (a) {
	return {$: 'Set_elm_builtin', a: a};
};
var $elm$core$Set$empty = $elm$core$Set$Set_elm_builtin($elm$core$Dict$empty);
var $mdgriffith$elm_ui$Internal$Model$lengthClassName = function (x) {
	switch (x.$) {
		case 'Px':
			var px = x.a;
			return $elm$core$String$fromInt(px) + 'px';
		case 'Content':
			return 'auto';
		case 'Fill':
			var i = x.a;
			return $elm$core$String$fromInt(i) + 'fr';
		case 'Min':
			var min = x.a;
			var len = x.b;
			return 'min' + ($elm$core$String$fromInt(min) + $mdgriffith$elm_ui$Internal$Model$lengthClassName(len));
		default:
			var max = x.a;
			var len = x.b;
			return 'max' + ($elm$core$String$fromInt(max) + $mdgriffith$elm_ui$Internal$Model$lengthClassName(len));
	}
};
var $mdgriffith$elm_ui$Internal$Model$floatClass = function (x) {
	return $elm$core$String$fromInt(
		$elm$core$Basics$round(x * 255));
};
var $mdgriffith$elm_ui$Internal$Model$transformClass = function (transform) {
	switch (transform.$) {
		case 'Untransformed':
			return $elm$core$Maybe$Nothing;
		case 'Moved':
			var _v1 = transform.a;
			var x = _v1.a;
			var y = _v1.b;
			var z = _v1.c;
			return $elm$core$Maybe$Just(
				'mv-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(x) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(y) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(z))))));
		default:
			var _v2 = transform.a;
			var tx = _v2.a;
			var ty = _v2.b;
			var tz = _v2.c;
			var _v3 = transform.b;
			var sx = _v3.a;
			var sy = _v3.b;
			var sz = _v3.c;
			var _v4 = transform.c;
			var ox = _v4.a;
			var oy = _v4.b;
			var oz = _v4.c;
			var angle = transform.d;
			return $elm$core$Maybe$Just(
				'tfrm-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(tx) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(ty) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(tz) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sx) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sy) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sz) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(ox) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(oy) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(oz) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(angle))))))))))))))))))));
	}
};
var $mdgriffith$elm_ui$Internal$Model$getStyleName = function (style) {
	switch (style.$) {
		case 'Shadows':
			var name = style.a;
			return name;
		case 'Transparency':
			var name = style.a;
			var o = style.b;
			return name;
		case 'Style':
			var _class = style.a;
			return _class;
		case 'FontFamily':
			var name = style.a;
			return name;
		case 'FontSize':
			var i = style.a;
			return 'font-size-' + $elm$core$String$fromInt(i);
		case 'Single':
			var _class = style.a;
			return _class;
		case 'Colored':
			var _class = style.a;
			return _class;
		case 'SpacingStyle':
			var cls = style.a;
			var x = style.b;
			var y = style.c;
			return cls;
		case 'PaddingStyle':
			var cls = style.a;
			var top = style.b;
			var right = style.c;
			var bottom = style.d;
			var left = style.e;
			return cls;
		case 'BorderWidth':
			var cls = style.a;
			var top = style.b;
			var right = style.c;
			var bottom = style.d;
			var left = style.e;
			return cls;
		case 'GridTemplateStyle':
			var template = style.a;
			return 'grid-rows-' + (A2(
				$elm$core$String$join,
				'-',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.rows)) + ('-cols-' + (A2(
				$elm$core$String$join,
				'-',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.columns)) + ('-space-x-' + ($mdgriffith$elm_ui$Internal$Model$lengthClassName(template.spacing.a) + ('-space-y-' + $mdgriffith$elm_ui$Internal$Model$lengthClassName(template.spacing.b)))))));
		case 'GridPosition':
			var pos = style.a;
			return 'gp grid-pos-' + ($elm$core$String$fromInt(pos.row) + ('-' + ($elm$core$String$fromInt(pos.col) + ('-' + ($elm$core$String$fromInt(pos.width) + ('-' + $elm$core$String$fromInt(pos.height)))))));
		case 'PseudoSelector':
			var selector = style.a;
			var subStyle = style.b;
			var name = function () {
				switch (selector.$) {
					case 'Focus':
						return 'fs';
					case 'Hover':
						return 'hv';
					default:
						return 'act';
				}
			}();
			return A2(
				$elm$core$String$join,
				' ',
				A2(
					$elm$core$List$map,
					function (sty) {
						var _v1 = $mdgriffith$elm_ui$Internal$Model$getStyleName(sty);
						if (_v1 === '') {
							return '';
						} else {
							var styleName = _v1;
							return styleName + ('-' + name);
						}
					},
					subStyle));
		default:
			var x = style.a;
			return A2(
				$elm$core$Maybe$withDefault,
				'',
				$mdgriffith$elm_ui$Internal$Model$transformClass(x));
	}
};
var $elm$core$Set$insert = F2(
	function (key, _v0) {
		var dict = _v0.a;
		return $elm$core$Set$Set_elm_builtin(
			A3($elm$core$Dict$insert, key, _Utils_Tuple0, dict));
	});
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (_v0.$ === 'Just') {
			return true;
		} else {
			return false;
		}
	});
var $elm$core$Set$member = F2(
	function (key, _v0) {
		var dict = _v0.a;
		return A2($elm$core$Dict$member, key, dict);
	});
var $mdgriffith$elm_ui$Internal$Model$reduceStyles = F2(
	function (style, nevermind) {
		var cache = nevermind.a;
		var existing = nevermind.b;
		var styleName = $mdgriffith$elm_ui$Internal$Model$getStyleName(style);
		return A2($elm$core$Set$member, styleName, cache) ? nevermind : _Utils_Tuple2(
			A2($elm$core$Set$insert, styleName, cache),
			A2($elm$core$List$cons, style, existing));
	});
var $mdgriffith$elm_ui$Internal$Model$Property = F2(
	function (a, b) {
		return {$: 'Property', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Style = F2(
	function (a, b) {
		return {$: 'Style', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$dot = function (c) {
	return '.' + c;
};
var $mdgriffith$elm_ui$Internal$Model$formatColor = function (_v0) {
	var red = _v0.a;
	var green = _v0.b;
	var blue = _v0.c;
	var alpha = _v0.d;
	return 'rgba(' + ($elm$core$String$fromInt(
		$elm$core$Basics$round(red * 255)) + ((',' + $elm$core$String$fromInt(
		$elm$core$Basics$round(green * 255))) + ((',' + $elm$core$String$fromInt(
		$elm$core$Basics$round(blue * 255))) + (',' + ($elm$core$String$fromFloat(alpha) + ')')))));
};
var $mdgriffith$elm_ui$Internal$Model$formatBoxShadow = function (shadow) {
	return A2(
		$elm$core$String$join,
		' ',
		A2(
			$elm$core$List$filterMap,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					shadow.inset ? $elm$core$Maybe$Just('inset') : $elm$core$Maybe$Nothing,
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.offset.a) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.offset.b) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.blur) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.size) + 'px'),
					$elm$core$Maybe$Just(
					$mdgriffith$elm_ui$Internal$Model$formatColor(shadow.color))
				])));
};
var $mdgriffith$elm_ui$Internal$Model$renderFocusStyle = function (focus) {
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Model$Style,
			$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.focusedWithin) + ':focus-within',
			A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'border-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.borderColor),
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'background-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.backgroundColor),
						A2(
						$elm$core$Maybe$map,
						function (shadow) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'box-shadow',
								$mdgriffith$elm_ui$Internal$Model$formatBoxShadow(
									{
										blur: shadow.blur,
										color: shadow.color,
										inset: false,
										offset: A2(
											$elm$core$Tuple$mapSecond,
											$elm$core$Basics$toFloat,
											A2($elm$core$Tuple$mapFirst, $elm$core$Basics$toFloat, shadow.offset)),
										size: shadow.size
									}));
						},
						focus.shadow),
						$elm$core$Maybe$Just(
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'outline', 'none'))
					]))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$Style,
			($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ':focus .focusable, ') + (($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + '.focusable:focus, ') + ('.ui-slide-bar:focus + ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ' .focusable-thumb'))),
			A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'border-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.borderColor),
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'background-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.backgroundColor),
						A2(
						$elm$core$Maybe$map,
						function (shadow) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'box-shadow',
								$mdgriffith$elm_ui$Internal$Model$formatBoxShadow(
									{
										blur: shadow.blur,
										color: shadow.color,
										inset: false,
										offset: A2(
											$elm$core$Tuple$mapSecond,
											$elm$core$Basics$toFloat,
											A2($elm$core$Tuple$mapFirst, $elm$core$Basics$toFloat, shadow.offset)),
										size: shadow.size
									}));
						},
						focus.shadow),
						$elm$core$Maybe$Just(
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'outline', 'none'))
					])))
		]);
};
var $elm$virtual_dom$VirtualDom$node = function (tag) {
	return _VirtualDom_node(
		_VirtualDom_noScript(tag));
};
var $elm$virtual_dom$VirtualDom$property = F2(
	function (key, value) {
		return A2(
			_VirtualDom_property,
			_VirtualDom_noInnerHtmlOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlJson(value));
	});
var $mdgriffith$elm_ui$Internal$Style$AllChildren = F2(
	function (a, b) {
		return {$: 'AllChildren', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Batch = function (a) {
	return {$: 'Batch', a: a};
};
var $mdgriffith$elm_ui$Internal$Style$Child = F2(
	function (a, b) {
		return {$: 'Child', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Class = F2(
	function (a, b) {
		return {$: 'Class', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Descriptor = F2(
	function (a, b) {
		return {$: 'Descriptor', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Left = {$: 'Left'};
var $mdgriffith$elm_ui$Internal$Style$Prop = F2(
	function (a, b) {
		return {$: 'Prop', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Right = {$: 'Right'};
var $mdgriffith$elm_ui$Internal$Style$Self = function (a) {
	return {$: 'Self', a: a};
};
var $mdgriffith$elm_ui$Internal$Style$Supports = F2(
	function (a, b) {
		return {$: 'Supports', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Content = function (a) {
	return {$: 'Content', a: a};
};
var $mdgriffith$elm_ui$Internal$Style$Bottom = {$: 'Bottom'};
var $mdgriffith$elm_ui$Internal$Style$CenterX = {$: 'CenterX'};
var $mdgriffith$elm_ui$Internal$Style$CenterY = {$: 'CenterY'};
var $mdgriffith$elm_ui$Internal$Style$Top = {$: 'Top'};
var $mdgriffith$elm_ui$Internal$Style$alignments = _List_fromArray(
	[$mdgriffith$elm_ui$Internal$Style$Top, $mdgriffith$elm_ui$Internal$Style$Bottom, $mdgriffith$elm_ui$Internal$Style$Right, $mdgriffith$elm_ui$Internal$Style$Left, $mdgriffith$elm_ui$Internal$Style$CenterX, $mdgriffith$elm_ui$Internal$Style$CenterY]);
var $mdgriffith$elm_ui$Internal$Style$contentName = function (desc) {
	switch (desc.a.$) {
		case 'Top':
			var _v1 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentTop);
		case 'Bottom':
			var _v2 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentBottom);
		case 'Right':
			var _v3 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentRight);
		case 'Left':
			var _v4 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentLeft);
		case 'CenterX':
			var _v5 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentCenterX);
		default:
			var _v6 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY);
	}
};
var $mdgriffith$elm_ui$Internal$Style$selfName = function (desc) {
	switch (desc.a.$) {
		case 'Top':
			var _v1 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignTop);
		case 'Bottom':
			var _v2 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignBottom);
		case 'Right':
			var _v3 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignRight);
		case 'Left':
			var _v4 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignLeft);
		case 'CenterX':
			var _v5 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterX);
		default:
			var _v6 = desc.a;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterY);
	}
};
var $mdgriffith$elm_ui$Internal$Style$describeAlignment = function (values) {
	var createDescription = function (alignment) {
		var _v0 = values(alignment);
		var content = _v0.a;
		var indiv = _v0.b;
		return _List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$contentName(
					$mdgriffith$elm_ui$Internal$Style$Content(alignment)),
				content),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$selfName(
							$mdgriffith$elm_ui$Internal$Style$Self(alignment)),
						indiv)
					]))
			]);
	};
	return $mdgriffith$elm_ui$Internal$Style$Batch(
		A2($elm$core$List$concatMap, createDescription, $mdgriffith$elm_ui$Internal$Style$alignments));
};
var $mdgriffith$elm_ui$Internal$Style$elDescription = _List_fromArray(
	[
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'column'),
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre'),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Descriptor,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hasBehind),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.behind),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '-1')
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Descriptor,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.seButton),
		_List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.text),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'auto !important')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightContent),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFillPortion),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthContent),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
			])),
		$mdgriffith$elm_ui$Internal$Style$describeAlignment(
		function (alignment) {
			switch (alignment.$) {
				case 'Top':
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', '0 !important')
							]));
				case 'Bottom':
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', '0 !important')
							]));
				case 'Right':
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
							]));
				case 'Left':
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
							]));
				case 'CenterX':
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
							]));
				default:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto')
									]))
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
							]));
			}
		})
	]);
var $mdgriffith$elm_ui$Internal$Style$gridAlignments = function (values) {
	var createDescription = function (alignment) {
		return _List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$selfName(
							$mdgriffith$elm_ui$Internal$Style$Self(alignment)),
						values(alignment))
					]))
			]);
	};
	return $mdgriffith$elm_ui$Internal$Style$Batch(
		A2($elm$core$List$concatMap, createDescription, $mdgriffith$elm_ui$Internal$Style$alignments));
};
var $mdgriffith$elm_ui$Internal$Style$Above = {$: 'Above'};
var $mdgriffith$elm_ui$Internal$Style$Behind = {$: 'Behind'};
var $mdgriffith$elm_ui$Internal$Style$Below = {$: 'Below'};
var $mdgriffith$elm_ui$Internal$Style$OnLeft = {$: 'OnLeft'};
var $mdgriffith$elm_ui$Internal$Style$OnRight = {$: 'OnRight'};
var $mdgriffith$elm_ui$Internal$Style$Within = {$: 'Within'};
var $mdgriffith$elm_ui$Internal$Style$locations = function () {
	var loc = $mdgriffith$elm_ui$Internal$Style$Above;
	var _v0 = function () {
		switch (loc.$) {
			case 'Above':
				return _Utils_Tuple0;
			case 'Below':
				return _Utils_Tuple0;
			case 'OnRight':
				return _Utils_Tuple0;
			case 'OnLeft':
				return _Utils_Tuple0;
			case 'Within':
				return _Utils_Tuple0;
			default:
				return _Utils_Tuple0;
		}
	}();
	return _List_fromArray(
		[$mdgriffith$elm_ui$Internal$Style$Above, $mdgriffith$elm_ui$Internal$Style$Below, $mdgriffith$elm_ui$Internal$Style$OnRight, $mdgriffith$elm_ui$Internal$Style$OnLeft, $mdgriffith$elm_ui$Internal$Style$Within, $mdgriffith$elm_ui$Internal$Style$Behind]);
}();
var $mdgriffith$elm_ui$Internal$Style$baseSheet = _List_fromArray(
	[
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		'html,body',
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'padding', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		_Utils_ap(
			$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
			_Utils_ap(
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.imageContainer))),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'img',
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'max-height', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'object-fit', 'cover')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'img',
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'max-width', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'object-fit', 'cover')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ':focus',
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'outline', 'none')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.root),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'min-height', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				_Utils_ap(
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill)),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inFront),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.nearby),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'fixed'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.nearby),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'relative'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
				$mdgriffith$elm_ui$Internal$Style$elDescription),
				$mdgriffith$elm_ui$Internal$Style$Batch(
				function (fn) {
					return A2($elm$core$List$map, fn, $mdgriffith$elm_ui$Internal$Style$locations);
				}(
					function (loc) {
						switch (loc.$) {
							case 'Above':
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.above),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'bottom', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
												])),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
												])),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 'Below':
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.below),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'bottom', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												])),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
												]))
										]));
							case 'OnRight':
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.onRight),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 'OnLeft':
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.onLeft),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'right', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 'Within':
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inFront),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							default:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.behind),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
						}
					}))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'relative'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'resize', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'box-sizing', 'border-box'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'padding', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-width', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'solid'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-size', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'color', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-family', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'line-height', '1'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'inherit'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.wrapped),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-wrap', 'wrap')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.noTextSelection),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-moz-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-webkit-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-ms-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'user-select', 'none')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cursorPointer),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'pointer')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cursorText),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'text')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.passPointerEvents),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none !important')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.capturePointerEvents),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto !important')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.transparent),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.opaque),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.hover, $mdgriffith$elm_ui$Internal$Style$classes.transparent)) + ':hover',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.hover, $mdgriffith$elm_ui$Internal$Style$classes.opaque)) + ':hover',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.focus, $mdgriffith$elm_ui$Internal$Style$classes.transparent)) + ':focus',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.focus, $mdgriffith$elm_ui$Internal$Style$classes.opaque)) + ':focus',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.active, $mdgriffith$elm_ui$Internal$Style$classes.transparent)) + ':active',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.active, $mdgriffith$elm_ui$Internal$Style$classes.opaque)) + ':active',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.transition),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Prop,
						'transition',
						A2(
							$elm$core$String$join,
							', ',
							A2(
								$elm$core$List$map,
								function (x) {
									return x + ' 160ms';
								},
								_List_fromArray(
									['transform', 'opacity', 'filter', 'background-color', 'color', 'font-size']))))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.scrollbars),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.scrollbarsX),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-x', 'auto'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.row),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.scrollbarsY),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-y', 'auto'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.column),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.clip),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.clipX),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-x', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.clipY),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-y', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthContent),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', 'auto')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.borderNone),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-width', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.borderDashed),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'dashed')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.borderDotted),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'dotted')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.borderSolid),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'solid')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.text),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-block')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputText),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'line-height', '1.05'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'background', 'transparent'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'inherit')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
				$mdgriffith$elm_ui$Internal$Style$elDescription),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.row),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', '0%'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthExact),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.link),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFillPortion),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.container),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerRight,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterX),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-left', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterX),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-right', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:only-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterY),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX + ' ~ u'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.alignContainerRight + (' ~ s.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX)),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment.$) {
								case 'Top':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
											]));
								case 'Bottom':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
											]));
								case 'Right':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
											]),
										_List_Nil);
								case 'Left':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
											]),
										_List_Nil);
								case 'CenterX':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
											]),
										_List_Nil);
								default:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
											]));
							}
						}),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.spaceEvenly),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'space-between')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputLabel),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'baseline')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.column),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'column'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', '0px'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'min-height', 'min-content'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightExact),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.heightFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFill),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthFillPortion),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthContent),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerBottom,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterY),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', '0 !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterY),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', '0 !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:only-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.alignCenterY),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY + ' ~ u'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.alignContainerBottom + (' ~ s.' + $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY)),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment.$) {
								case 'Top':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto')
											]));
								case 'Bottom':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto')
											]));
								case 'Right':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
											]));
								case 'Left':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
											]));
								case 'CenterX':
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
											]));
								default:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
											]),
										_List_Nil);
							}
						}),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.container),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.spaceEvenly),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'space-between')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.grid),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', '-ms-grid'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'.gp',
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Supports,
						_Utils_Tuple2('display', 'grid'),
						_List_fromArray(
							[
								_Utils_Tuple2('display', 'grid')
							])),
						$mdgriffith$elm_ui$Internal$Style$gridAlignments(
						function (alignment) {
							switch (alignment.$) {
								case 'Top':
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
										]);
								case 'Bottom':
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
										]);
								case 'Right':
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
										]);
								case 'Left':
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
										]);
								case 'CenterX':
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
										]);
								default:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
										]);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.page),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any + ':first-child'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot(
							$mdgriffith$elm_ui$Internal$Style$classes.any + ($mdgriffith$elm_ui$Internal$Style$selfName(
								$mdgriffith$elm_ui$Internal$Style$Self($mdgriffith$elm_ui$Internal$Style$Left)) + (':first-child + .' + $mdgriffith$elm_ui$Internal$Style$classes.any))),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot(
							$mdgriffith$elm_ui$Internal$Style$classes.any + ($mdgriffith$elm_ui$Internal$Style$selfName(
								$mdgriffith$elm_ui$Internal$Style$Self($mdgriffith$elm_ui$Internal$Style$Right)) + (':first-child + .' + $mdgriffith$elm_ui$Internal$Style$classes.any))),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment.$) {
								case 'Top':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 'Bottom':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 'Right':
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'right'),
												A2(
												$mdgriffith$elm_ui$Internal$Style$Descriptor,
												'::after',
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', '\"\"'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'table'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'clear', 'both')
													]))
											]));
								case 'Left':
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'left'),
												A2(
												$mdgriffith$elm_ui$Internal$Style$Descriptor,
												'::after',
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', '\"\"'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'table'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'clear', 'both')
													]))
											]));
								case 'CenterX':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								default:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputMultiline),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'background-color', 'transparent')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputMultilineWrapper),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputMultilineParent),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'text'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inputMultilineFiller),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'color', 'transparent')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.paragraph),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-wrap', 'break-word'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hasBehind),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.behind),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '-1')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.text),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.paragraph),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								'::after',
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', 'none')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								'::before',
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', 'none')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.single),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.widthExact),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-block')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.inFront),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.behind),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.above),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.below),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.onRight),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.onLeft),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.text),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.row),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.column),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-flex')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.grid),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-grid')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment.$) {
								case 'Top':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 'Bottom':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 'Right':
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'right')
											]));
								case 'Left':
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'left')
											]));
								case 'CenterX':
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								default:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				'.hidden',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'none')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textThin),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '100')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textExtraLight),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '200')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textLight),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '300')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textNormalWeight),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '400')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textMedium),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '500')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textSemiBold),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '600')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.bold),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '700')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textExtraBold),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '800')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textHeavy),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '900')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.italic),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'italic')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.strike),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'line-through')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.underline),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'underline'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip-ink', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip', 'ink')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				_Utils_ap(
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.underline),
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.strike)),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'line-through underline'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip-ink', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip', 'ink')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textUnitalicized),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'normal')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textJustify),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'justify')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textJustifyAll),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'justify-all')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textCenter),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'center')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textRight),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'right')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.textLeft),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'left')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				'.modal',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'fixed'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none')
					]))
			]))
	]);
var $mdgriffith$elm_ui$Internal$Style$fontVariant = function (_var) {
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Style$Class,
			'.v-' + _var,
			_List_fromArray(
				[
					A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', '\"' + (_var + '\"'))
				])),
			A2(
			$mdgriffith$elm_ui$Internal$Style$Class,
			'.v-' + (_var + '-off'),
			_List_fromArray(
				[
					A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', '\"' + (_var + '\" 0'))
				]))
		]);
};
var $mdgriffith$elm_ui$Internal$Style$commonValues = $elm$core$List$concat(
	_List_fromArray(
		[
			A2(
			$elm$core$List$map,
			function (x) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.border-' + $elm$core$String$fromInt(x),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'border-width',
							$elm$core$String$fromInt(x) + 'px')
						]));
			},
			A2($elm$core$List$range, 0, 6)),
			A2(
			$elm$core$List$map,
			function (i) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.font-size-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'font-size',
							$elm$core$String$fromInt(i) + 'px')
						]));
			},
			A2($elm$core$List$range, 8, 32)),
			A2(
			$elm$core$List$map,
			function (i) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.p-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'padding',
							$elm$core$String$fromInt(i) + 'px')
						]));
			},
			A2($elm$core$List$range, 0, 24)),
			_List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Class,
				'.v-smcp',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-variant', 'small-caps')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Class,
				'.v-smcp-off',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-variant', 'normal')
					]))
			]),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('zero'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('onum'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('liga'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('dlig'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('ordn'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('tnum'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('afrc'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('frac')
		]));
var $mdgriffith$elm_ui$Internal$Style$explainer = '\n.explain {\n    border: 6px solid rgb(174, 121, 15) !important;\n}\n.explain > .' + ($mdgriffith$elm_ui$Internal$Style$classes.any + (' {\n    border: 4px dashed rgb(0, 151, 167) !important;\n}\n\n.ctr {\n    border: none !important;\n}\n.explain > .ctr > .' + ($mdgriffith$elm_ui$Internal$Style$classes.any + ' {\n    border: 4px dashed rgb(0, 151, 167) !important;\n}\n\n')));
var $mdgriffith$elm_ui$Internal$Style$inputTextReset = '\ninput[type="search"],\ninput[type="search"]::-webkit-search-decoration,\ninput[type="search"]::-webkit-search-cancel-button,\ninput[type="search"]::-webkit-search-results-button,\ninput[type="search"]::-webkit-search-results-decoration {\n  -webkit-appearance:none;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$sliderReset = '\ninput[type=range] {\n  -webkit-appearance: none; \n  background: transparent;\n  position:absolute;\n  left:0;\n  top:0;\n  z-index:10;\n  width: 100%;\n  outline: dashed 1px;\n  height: 100%;\n  opacity: 0;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$thumbReset = '\ninput[type=range]::-webkit-slider-thumb {\n    -webkit-appearance: none;\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range]::-moz-range-thumb {\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range]::-ms-thumb {\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range][orient=vertical]{\n    writing-mode: bt-lr; /* IE */\n    -webkit-appearance: slider-vertical;  /* WebKit */\n}\n';
var $mdgriffith$elm_ui$Internal$Style$trackReset = '\ninput[type=range]::-moz-range-track {\n    background: transparent;\n    cursor: pointer;\n}\ninput[type=range]::-ms-track {\n    background: transparent;\n    cursor: pointer;\n}\ninput[type=range]::-webkit-slider-runnable-track {\n    background: transparent;\n    cursor: pointer;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$overrides = '@media screen and (-ms-high-contrast: active), (-ms-high-contrast: none) {' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.row) + (' > ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + (' { flex-basis: auto !important; } ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.row) + (' > ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.container) + (' { flex-basis: auto !important; }}' + ($mdgriffith$elm_ui$Internal$Style$inputTextReset + ($mdgriffith$elm_ui$Internal$Style$sliderReset + ($mdgriffith$elm_ui$Internal$Style$trackReset + ($mdgriffith$elm_ui$Internal$Style$thumbReset + $mdgriffith$elm_ui$Internal$Style$explainer)))))))))))))));
var $mdgriffith$elm_ui$Internal$Style$Intermediate = function (a) {
	return {$: 'Intermediate', a: a};
};
var $mdgriffith$elm_ui$Internal$Style$emptyIntermediate = F2(
	function (selector, closing) {
		return $mdgriffith$elm_ui$Internal$Style$Intermediate(
			{closing: closing, others: _List_Nil, props: _List_Nil, selector: selector});
	});
var $mdgriffith$elm_ui$Internal$Style$renderRules = F2(
	function (_v0, rulesToRender) {
		var parent = _v0.a;
		var generateIntermediates = F2(
			function (rule, rendered) {
				switch (rule.$) {
					case 'Prop':
						var name = rule.a;
						var val = rule.b;
						return _Utils_update(
							rendered,
							{
								props: A2(
									$elm$core$List$cons,
									_Utils_Tuple2(name, val),
									rendered.props)
							});
					case 'Supports':
						var _v2 = rule.a;
						var prop = _v2.a;
						var value = _v2.b;
						var props = rule.b;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Style$Intermediate(
										{closing: '\n}', others: _List_Nil, props: props, selector: '@supports (' + (prop + (':' + (value + (') {' + parent.selector))))}),
									rendered.others)
							});
					case 'Adjacent':
						var selector = rule.a;
						var adjRules = rule.b;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.selector + (' + ' + selector), ''),
										adjRules),
									rendered.others)
							});
					case 'Child':
						var child = rule.a;
						var childRules = rule.b;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.selector + (' > ' + child), ''),
										childRules),
									rendered.others)
							});
					case 'AllChildren':
						var child = rule.a;
						var childRules = rule.b;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.selector + (' ' + child), ''),
										childRules),
									rendered.others)
							});
					case 'Descriptor':
						var descriptor = rule.a;
						var descriptorRules = rule.b;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2(
											$mdgriffith$elm_ui$Internal$Style$emptyIntermediate,
											_Utils_ap(parent.selector, descriptor),
											''),
										descriptorRules),
									rendered.others)
							});
					default:
						var batched = rule.a;
						return _Utils_update(
							rendered,
							{
								others: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.selector, ''),
										batched),
									rendered.others)
							});
				}
			});
		return $mdgriffith$elm_ui$Internal$Style$Intermediate(
			A3($elm$core$List$foldr, generateIntermediates, parent, rulesToRender));
	});
var $mdgriffith$elm_ui$Internal$Style$renderCompact = function (styleClasses) {
	var renderValues = function (values) {
		return $elm$core$String$concat(
			A2(
				$elm$core$List$map,
				function (_v3) {
					var x = _v3.a;
					var y = _v3.b;
					return x + (':' + (y + ';'));
				},
				values));
	};
	var renderClass = function (rule) {
		var _v2 = rule.props;
		if (!_v2.b) {
			return '';
		} else {
			return rule.selector + ('{' + (renderValues(rule.props) + (rule.closing + '}')));
		}
	};
	var renderIntermediate = function (_v0) {
		var rule = _v0.a;
		return _Utils_ap(
			renderClass(rule),
			$elm$core$String$concat(
				A2($elm$core$List$map, renderIntermediate, rule.others)));
	};
	return $elm$core$String$concat(
		A2(
			$elm$core$List$map,
			renderIntermediate,
			A3(
				$elm$core$List$foldr,
				F2(
					function (_v1, existing) {
						var name = _v1.a;
						var styleRules = _v1.b;
						return A2(
							$elm$core$List$cons,
							A2(
								$mdgriffith$elm_ui$Internal$Style$renderRules,
								A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, name, ''),
								styleRules),
							existing);
					}),
				_List_Nil,
				styleClasses)));
};
var $mdgriffith$elm_ui$Internal$Style$rules = _Utils_ap(
	$mdgriffith$elm_ui$Internal$Style$overrides,
	$mdgriffith$elm_ui$Internal$Style$renderCompact(
		_Utils_ap($mdgriffith$elm_ui$Internal$Style$baseSheet, $mdgriffith$elm_ui$Internal$Style$commonValues)));
var $mdgriffith$elm_ui$Internal$Model$staticRoot = function (opts) {
	var _v0 = opts.mode;
	switch (_v0.$) {
		case 'Layout':
			return A3(
				$elm$virtual_dom$VirtualDom$node,
				'div',
				_List_Nil,
				_List_fromArray(
					[
						A3(
						$elm$virtual_dom$VirtualDom$node,
						'style',
						_List_Nil,
						_List_fromArray(
							[
								$elm$virtual_dom$VirtualDom$text($mdgriffith$elm_ui$Internal$Style$rules)
							]))
					]));
		case 'NoStaticStyleSheet':
			return $elm$virtual_dom$VirtualDom$text('');
		default:
			return A3(
				$elm$virtual_dom$VirtualDom$node,
				'elm-ui-static-rules',
				_List_fromArray(
					[
						A2(
						$elm$virtual_dom$VirtualDom$property,
						'rules',
						$elm$json$Json$Encode$string($mdgriffith$elm_ui$Internal$Style$rules))
					]),
				_List_Nil);
	}
};
var $mdgriffith$elm_ui$Internal$Model$fontName = function (font) {
	switch (font.$) {
		case 'Serif':
			return 'serif';
		case 'SansSerif':
			return 'sans-serif';
		case 'Monospace':
			return 'monospace';
		case 'Typeface':
			var name = font.a;
			return '\"' + (name + '\"');
		case 'ImportFont':
			var name = font.a;
			var url = font.b;
			return '\"' + (name + '\"');
		default:
			var name = font.a.name;
			return '\"' + (name + '\"');
	}
};
var $mdgriffith$elm_ui$Internal$Model$isSmallCaps = function (_var) {
	switch (_var.$) {
		case 'VariantActive':
			var name = _var.a;
			return name === 'smcp';
		case 'VariantOff':
			var name = _var.a;
			return false;
		default:
			var name = _var.a;
			var index = _var.b;
			return (name === 'smcp') && (index === 1);
	}
};
var $mdgriffith$elm_ui$Internal$Model$hasSmallCaps = function (typeface) {
	if (typeface.$ === 'FontWith') {
		var font = typeface.a;
		return A2($elm$core$List$any, $mdgriffith$elm_ui$Internal$Model$isSmallCaps, font.variants);
	} else {
		return false;
	}
};
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $mdgriffith$elm_ui$Internal$Model$renderProps = F3(
	function (force, _v0, existing) {
		var key = _v0.a;
		var val = _v0.b;
		return force ? (existing + ('\n  ' + (key + (': ' + (val + ' !important;'))))) : (existing + ('\n  ' + (key + (': ' + (val + ';')))));
	});
var $mdgriffith$elm_ui$Internal$Model$renderStyle = F4(
	function (options, maybePseudo, selector, props) {
		if (maybePseudo.$ === 'Nothing') {
			return _List_fromArray(
				[
					selector + ('{' + (A3(
					$elm$core$List$foldl,
					$mdgriffith$elm_ui$Internal$Model$renderProps(false),
					'',
					props) + '\n}'))
				]);
		} else {
			var pseudo = maybePseudo.a;
			switch (pseudo.$) {
				case 'Hover':
					var _v2 = options.hover;
					switch (_v2.$) {
						case 'NoHover':
							return _List_Nil;
						case 'ForceHover':
							return _List_fromArray(
								[
									selector + ('-hv {' + (A3(
									$elm$core$List$foldl,
									$mdgriffith$elm_ui$Internal$Model$renderProps(true),
									'',
									props) + '\n}'))
								]);
						default:
							return _List_fromArray(
								[
									selector + ('-hv:hover {' + (A3(
									$elm$core$List$foldl,
									$mdgriffith$elm_ui$Internal$Model$renderProps(false),
									'',
									props) + '\n}'))
								]);
					}
				case 'Focus':
					var renderedProps = A3(
						$elm$core$List$foldl,
						$mdgriffith$elm_ui$Internal$Model$renderProps(false),
						'',
						props);
					return _List_fromArray(
						[
							selector + ('-fs:focus {' + (renderedProps + '\n}')),
							('.' + ($mdgriffith$elm_ui$Internal$Style$classes.any + (':focus ' + (selector + '-fs  {')))) + (renderedProps + '\n}'),
							(selector + '-fs:focus-within {') + (renderedProps + '\n}'),
							('.ui-slide-bar:focus + ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.any) + (' .focusable-thumb' + (selector + '-fs {')))) + (renderedProps + '\n}')
						]);
				default:
					return _List_fromArray(
						[
							selector + ('-act:active {' + (A3(
							$elm$core$List$foldl,
							$mdgriffith$elm_ui$Internal$Model$renderProps(false),
							'',
							props) + '\n}'))
						]);
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$renderVariant = function (_var) {
	switch (_var.$) {
		case 'VariantActive':
			var name = _var.a;
			return '\"' + (name + '\"');
		case 'VariantOff':
			var name = _var.a;
			return '\"' + (name + '\" 0');
		default:
			var name = _var.a;
			var index = _var.b;
			return '\"' + (name + ('\" ' + $elm$core$String$fromInt(index)));
	}
};
var $mdgriffith$elm_ui$Internal$Model$renderVariants = function (typeface) {
	if (typeface.$ === 'FontWith') {
		var font = typeface.a;
		return $elm$core$Maybe$Just(
			A2(
				$elm$core$String$join,
				', ',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$renderVariant, font.variants)));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$transformValue = function (transform) {
	switch (transform.$) {
		case 'Untransformed':
			return $elm$core$Maybe$Nothing;
		case 'Moved':
			var _v1 = transform.a;
			var x = _v1.a;
			var y = _v1.b;
			var z = _v1.c;
			return $elm$core$Maybe$Just(
				'translate3d(' + ($elm$core$String$fromFloat(x) + ('px, ' + ($elm$core$String$fromFloat(y) + ('px, ' + ($elm$core$String$fromFloat(z) + 'px)'))))));
		default:
			var _v2 = transform.a;
			var tx = _v2.a;
			var ty = _v2.b;
			var tz = _v2.c;
			var _v3 = transform.b;
			var sx = _v3.a;
			var sy = _v3.b;
			var sz = _v3.c;
			var _v4 = transform.c;
			var ox = _v4.a;
			var oy = _v4.b;
			var oz = _v4.c;
			var angle = transform.d;
			var translate = 'translate3d(' + ($elm$core$String$fromFloat(tx) + ('px, ' + ($elm$core$String$fromFloat(ty) + ('px, ' + ($elm$core$String$fromFloat(tz) + 'px)')))));
			var scale = 'scale3d(' + ($elm$core$String$fromFloat(sx) + (', ' + ($elm$core$String$fromFloat(sy) + (', ' + ($elm$core$String$fromFloat(sz) + ')')))));
			var rotate = 'rotate3d(' + ($elm$core$String$fromFloat(ox) + (', ' + ($elm$core$String$fromFloat(oy) + (', ' + ($elm$core$String$fromFloat(oz) + (', ' + ($elm$core$String$fromFloat(angle) + 'rad)')))))));
			return $elm$core$Maybe$Just(translate + (' ' + (scale + (' ' + rotate))));
	}
};
var $mdgriffith$elm_ui$Internal$Model$renderStyleRule = F3(
	function (options, rule, maybePseudo) {
		switch (rule.$) {
			case 'Style':
				var selector = rule.a;
				var props = rule.b;
				return A4($mdgriffith$elm_ui$Internal$Model$renderStyle, options, maybePseudo, selector, props);
			case 'Shadows':
				var name = rule.a;
				var prop = rule.b;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + name,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Internal$Model$Property, 'box-shadow', prop)
						]));
			case 'Transparency':
				var name = rule.a;
				var transparency = rule.b;
				var opacity = A2(
					$elm$core$Basics$max,
					0,
					A2($elm$core$Basics$min, 1, 1 - transparency));
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + name,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'opacity',
							$elm$core$String$fromFloat(opacity))
						]));
			case 'FontSize':
				var i = rule.a;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.font-size-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'font-size',
							$elm$core$String$fromInt(i) + 'px')
						]));
			case 'FontFamily':
				var name = rule.a;
				var typefaces = rule.b;
				var features = A2(
					$elm$core$String$join,
					', ',
					A2($elm$core$List$filterMap, $mdgriffith$elm_ui$Internal$Model$renderVariants, typefaces));
				var families = _List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Model$Property,
						'font-family',
						A2(
							$elm$core$String$join,
							', ',
							A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$fontName, typefaces))),
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'font-feature-settings', features),
						A2(
						$mdgriffith$elm_ui$Internal$Model$Property,
						'font-variant',
						A2($elm$core$List$any, $mdgriffith$elm_ui$Internal$Model$hasSmallCaps, typefaces) ? 'small-caps' : 'normal')
					]);
				return A4($mdgriffith$elm_ui$Internal$Model$renderStyle, options, maybePseudo, '.' + name, families);
			case 'Single':
				var _class = rule.a;
				var prop = rule.b;
				var val = rule.c;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + _class,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Internal$Model$Property, prop, val)
						]));
			case 'Colored':
				var _class = rule.a;
				var prop = rule.b;
				var color = rule.c;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + _class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							prop,
							$mdgriffith$elm_ui$Internal$Model$formatColor(color))
						]));
			case 'SpacingStyle':
				var cls = rule.a;
				var x = rule.b;
				var y = rule.c;
				var yPx = $elm$core$String$fromInt(y) + 'px';
				var xPx = $elm$core$String$fromInt(x) + 'px';
				var single = '.' + $mdgriffith$elm_ui$Internal$Style$classes.single;
				var row = '.' + $mdgriffith$elm_ui$Internal$Style$classes.row;
				var wrappedRow = '.' + ($mdgriffith$elm_ui$Internal$Style$classes.wrapped + row);
				var right = '.' + $mdgriffith$elm_ui$Internal$Style$classes.alignRight;
				var paragraph = '.' + $mdgriffith$elm_ui$Internal$Style$classes.paragraph;
				var page = '.' + $mdgriffith$elm_ui$Internal$Style$classes.page;
				var left = '.' + $mdgriffith$elm_ui$Internal$Style$classes.alignLeft;
				var halfY = $elm$core$String$fromFloat(y / 2) + 'px';
				var halfX = $elm$core$String$fromFloat(x / 2) + 'px';
				var column = '.' + $mdgriffith$elm_ui$Internal$Style$classes.column;
				var _class = '.' + cls;
				var any = '.' + $mdgriffith$elm_ui$Internal$Style$classes.any;
				return $elm$core$List$concat(
					_List_fromArray(
						[
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (row + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (wrappedRow + (' > ' + any)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin', halfY + (' ' + halfX))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (column + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-top', yPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-top', yPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + left)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-right', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + right)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_Utils_ap(_class, paragraph),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'line-height',
									'calc(1em + ' + ($elm$core$String$fromInt(y) + 'px)'))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							'textarea' + (any + _class),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'line-height',
									'calc(1em + ' + ($elm$core$String$fromInt(y) + 'px)')),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'height',
									'calc(100% + ' + ($elm$core$String$fromInt(y) + 'px)'))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + (' > ' + left)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-right', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + (' > ' + right)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + '::after'),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'content', '\'\''),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'display', 'block'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'height', '0'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'width', '0'),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'margin-top',
									$elm$core$String$fromInt((-1) * ((y / 2) | 0)) + 'px')
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + '::before'),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'content', '\'\''),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'display', 'block'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'height', '0'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'width', '0'),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'margin-bottom',
									$elm$core$String$fromInt((-1) * ((y / 2) | 0)) + 'px')
								]))
						]));
			case 'PaddingStyle':
				var cls = rule.a;
				var top = rule.b;
				var right = rule.c;
				var bottom = rule.d;
				var left = rule.e;
				var _class = '.' + cls;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					_class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'padding',
							$elm$core$String$fromFloat(top) + ('px ' + ($elm$core$String$fromFloat(right) + ('px ' + ($elm$core$String$fromFloat(bottom) + ('px ' + ($elm$core$String$fromFloat(left) + 'px')))))))
						]));
			case 'BorderWidth':
				var cls = rule.a;
				var top = rule.b;
				var right = rule.c;
				var bottom = rule.d;
				var left = rule.e;
				var _class = '.' + cls;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					_class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'border-width',
							$elm$core$String$fromInt(top) + ('px ' + ($elm$core$String$fromInt(right) + ('px ' + ($elm$core$String$fromInt(bottom) + ('px ' + ($elm$core$String$fromInt(left) + 'px')))))))
						]));
			case 'GridTemplateStyle':
				var template = rule.a;
				var toGridLengthHelper = F3(
					function (minimum, maximum, x) {
						toGridLengthHelper:
						while (true) {
							switch (x.$) {
								case 'Px':
									var px = x.a;
									return $elm$core$String$fromInt(px) + 'px';
								case 'Content':
									var _v2 = _Utils_Tuple2(minimum, maximum);
									if (_v2.a.$ === 'Nothing') {
										if (_v2.b.$ === 'Nothing') {
											var _v3 = _v2.a;
											var _v4 = _v2.b;
											return 'max-content';
										} else {
											var _v6 = _v2.a;
											var maxSize = _v2.b.a;
											return 'minmax(max-content, ' + ($elm$core$String$fromInt(maxSize) + 'px)');
										}
									} else {
										if (_v2.b.$ === 'Nothing') {
											var minSize = _v2.a.a;
											var _v5 = _v2.b;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + 'max-content)'));
										} else {
											var minSize = _v2.a.a;
											var maxSize = _v2.b.a;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(maxSize) + 'px)')));
										}
									}
								case 'Fill':
									var i = x.a;
									var _v7 = _Utils_Tuple2(minimum, maximum);
									if (_v7.a.$ === 'Nothing') {
										if (_v7.b.$ === 'Nothing') {
											var _v8 = _v7.a;
											var _v9 = _v7.b;
											return $elm$core$String$fromInt(i) + 'fr';
										} else {
											var _v11 = _v7.a;
											var maxSize = _v7.b.a;
											return 'minmax(max-content, ' + ($elm$core$String$fromInt(maxSize) + 'px)');
										}
									} else {
										if (_v7.b.$ === 'Nothing') {
											var minSize = _v7.a.a;
											var _v10 = _v7.b;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(i) + ('fr' + 'fr)'))));
										} else {
											var minSize = _v7.a.a;
											var maxSize = _v7.b.a;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(maxSize) + 'px)')));
										}
									}
								case 'Min':
									var m = x.a;
									var len = x.b;
									var $temp$minimum = $elm$core$Maybe$Just(m),
										$temp$maximum = maximum,
										$temp$x = len;
									minimum = $temp$minimum;
									maximum = $temp$maximum;
									x = $temp$x;
									continue toGridLengthHelper;
								default:
									var m = x.a;
									var len = x.b;
									var $temp$minimum = minimum,
										$temp$maximum = $elm$core$Maybe$Just(m),
										$temp$x = len;
									minimum = $temp$minimum;
									maximum = $temp$maximum;
									x = $temp$x;
									continue toGridLengthHelper;
							}
						}
					});
				var toGridLength = function (x) {
					return A3(toGridLengthHelper, $elm$core$Maybe$Nothing, $elm$core$Maybe$Nothing, x);
				};
				var xSpacing = toGridLength(template.spacing.a);
				var ySpacing = toGridLength(template.spacing.b);
				var rows = function (x) {
					return 'grid-template-rows: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						' ',
						A2($elm$core$List$map, toGridLength, template.rows)));
				var msRows = function (x) {
					return '-ms-grid-rows: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						ySpacing,
						A2($elm$core$List$map, toGridLength, template.columns)));
				var msColumns = function (x) {
					return '-ms-grid-columns: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						ySpacing,
						A2($elm$core$List$map, toGridLength, template.columns)));
				var gapY = 'grid-row-gap:' + (toGridLength(template.spacing.b) + ';');
				var gapX = 'grid-column-gap:' + (toGridLength(template.spacing.a) + ';');
				var columns = function (x) {
					return 'grid-template-columns: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						' ',
						A2($elm$core$List$map, toGridLength, template.columns)));
				var _class = '.grid-rows-' + (A2(
					$elm$core$String$join,
					'-',
					A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.rows)) + ('-cols-' + (A2(
					$elm$core$String$join,
					'-',
					A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.columns)) + ('-space-x-' + ($mdgriffith$elm_ui$Internal$Model$lengthClassName(template.spacing.a) + ('-space-y-' + $mdgriffith$elm_ui$Internal$Model$lengthClassName(template.spacing.b)))))));
				var modernGrid = _class + ('{' + (columns + (rows + (gapX + (gapY + '}')))));
				var supports = '@supports (display:grid) {' + (modernGrid + '}');
				var base = _class + ('{' + (msColumns + (msRows + '}')));
				return _List_fromArray(
					[base, supports]);
			case 'GridPosition':
				var position = rule.a;
				var msPosition = A2(
					$elm$core$String$join,
					' ',
					_List_fromArray(
						[
							'-ms-grid-row: ' + ($elm$core$String$fromInt(position.row) + ';'),
							'-ms-grid-row-span: ' + ($elm$core$String$fromInt(position.height) + ';'),
							'-ms-grid-column: ' + ($elm$core$String$fromInt(position.col) + ';'),
							'-ms-grid-column-span: ' + ($elm$core$String$fromInt(position.width) + ';')
						]));
				var modernPosition = A2(
					$elm$core$String$join,
					' ',
					_List_fromArray(
						[
							'grid-row: ' + ($elm$core$String$fromInt(position.row) + (' / ' + ($elm$core$String$fromInt(position.row + position.height) + ';'))),
							'grid-column: ' + ($elm$core$String$fromInt(position.col) + (' / ' + ($elm$core$String$fromInt(position.col + position.width) + ';')))
						]));
				var _class = '.grid-pos-' + ($elm$core$String$fromInt(position.row) + ('-' + ($elm$core$String$fromInt(position.col) + ('-' + ($elm$core$String$fromInt(position.width) + ('-' + $elm$core$String$fromInt(position.height)))))));
				var modernGrid = _class + ('{' + (modernPosition + '}'));
				var supports = '@supports (display:grid) {' + (modernGrid + '}');
				var base = _class + ('{' + (msPosition + '}'));
				return _List_fromArray(
					[base, supports]);
			case 'PseudoSelector':
				var _class = rule.a;
				var styles = rule.b;
				var renderPseudoRule = function (style) {
					return A3(
						$mdgriffith$elm_ui$Internal$Model$renderStyleRule,
						options,
						style,
						$elm$core$Maybe$Just(_class));
				};
				return A2($elm$core$List$concatMap, renderPseudoRule, styles);
			default:
				var transform = rule.a;
				var val = $mdgriffith$elm_ui$Internal$Model$transformValue(transform);
				var _class = $mdgriffith$elm_ui$Internal$Model$transformClass(transform);
				var _v12 = _Utils_Tuple2(_class, val);
				if ((_v12.a.$ === 'Just') && (_v12.b.$ === 'Just')) {
					var cls = _v12.a.a;
					var v = _v12.b.a;
					return A4(
						$mdgriffith$elm_ui$Internal$Model$renderStyle,
						options,
						maybePseudo,
						'.' + cls,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Model$Property, 'transform', v)
							]));
				} else {
					return _List_Nil;
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$encodeStyles = F2(
	function (options, stylesheet) {
		return $elm$json$Json$Encode$object(
			A2(
				$elm$core$List$map,
				function (style) {
					var styled = A3($mdgriffith$elm_ui$Internal$Model$renderStyleRule, options, style, $elm$core$Maybe$Nothing);
					return _Utils_Tuple2(
						$mdgriffith$elm_ui$Internal$Model$getStyleName(style),
						A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, styled));
				},
				stylesheet));
	});
var $mdgriffith$elm_ui$Internal$Model$bracket = F2(
	function (selector, rules) {
		var renderPair = function (_v0) {
			var name = _v0.a;
			var val = _v0.b;
			return name + (': ' + (val + ';'));
		};
		return selector + (' {' + (A2(
			$elm$core$String$join,
			'',
			A2($elm$core$List$map, renderPair, rules)) + '}'));
	});
var $mdgriffith$elm_ui$Internal$Model$fontRule = F3(
	function (name, modifier, _v0) {
		var parentAdj = _v0.a;
		var textAdjustment = _v0.b;
		return _List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Model$bracket, '.' + (name + ('.' + (modifier + (', ' + ('.' + (name + (' .' + modifier))))))), parentAdj),
				A2($mdgriffith$elm_ui$Internal$Model$bracket, '.' + (name + ('.' + (modifier + ('> .' + ($mdgriffith$elm_ui$Internal$Style$classes.text + (', .' + (name + (' .' + (modifier + (' > .' + $mdgriffith$elm_ui$Internal$Style$classes.text)))))))))), textAdjustment)
			]);
	});
var $mdgriffith$elm_ui$Internal$Model$renderFontAdjustmentRule = F3(
	function (fontToAdjust, _v0, otherFontName) {
		var full = _v0.a;
		var capital = _v0.b;
		var name = _Utils_eq(fontToAdjust, otherFontName) ? fontToAdjust : (otherFontName + (' .' + fontToAdjust));
		return A2(
			$elm$core$String$join,
			' ',
			_Utils_ap(
				A3($mdgriffith$elm_ui$Internal$Model$fontRule, name, $mdgriffith$elm_ui$Internal$Style$classes.sizeByCapital, capital),
				A3($mdgriffith$elm_ui$Internal$Model$fontRule, name, $mdgriffith$elm_ui$Internal$Style$classes.fullSize, full)));
	});
var $mdgriffith$elm_ui$Internal$Model$renderNullAdjustmentRule = F2(
	function (fontToAdjust, otherFontName) {
		var name = _Utils_eq(fontToAdjust, otherFontName) ? fontToAdjust : (otherFontName + (' .' + fontToAdjust));
		return A2(
			$elm$core$String$join,
			' ',
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Internal$Model$bracket,
					'.' + (name + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.sizeByCapital + (', ' + ('.' + (name + (' .' + $mdgriffith$elm_ui$Internal$Style$classes.sizeByCapital))))))),
					_List_fromArray(
						[
							_Utils_Tuple2('line-height', '1')
						])),
					A2(
					$mdgriffith$elm_ui$Internal$Model$bracket,
					'.' + (name + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.sizeByCapital + ('> .' + ($mdgriffith$elm_ui$Internal$Style$classes.text + (', .' + (name + (' .' + ($mdgriffith$elm_ui$Internal$Style$classes.sizeByCapital + (' > .' + $mdgriffith$elm_ui$Internal$Style$classes.text)))))))))),
					_List_fromArray(
						[
							_Utils_Tuple2('vertical-align', '0'),
							_Utils_Tuple2('line-height', '1')
						]))
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$adjust = F3(
	function (size, height, vertical) {
		return {height: height / size, size: size, vertical: vertical};
	});
var $elm$core$List$minimum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$min, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$convertAdjustment = function (adjustment) {
	var lines = _List_fromArray(
		[adjustment.capital, adjustment.baseline, adjustment.descender, adjustment.lowercase]);
	var lineHeight = 1.5;
	var normalDescender = (lineHeight - 1) / 2;
	var oldMiddle = lineHeight / 2;
	var descender = A2(
		$elm$core$Maybe$withDefault,
		adjustment.descender,
		$elm$core$List$minimum(lines));
	var newBaseline = A2(
		$elm$core$Maybe$withDefault,
		adjustment.baseline,
		$elm$core$List$minimum(
			A2(
				$elm$core$List$filter,
				function (x) {
					return !_Utils_eq(x, descender);
				},
				lines)));
	var base = lineHeight;
	var ascender = A2(
		$elm$core$Maybe$withDefault,
		adjustment.capital,
		$elm$core$List$maximum(lines));
	var capitalSize = 1 / (ascender - newBaseline);
	var capitalVertical = 1 - ascender;
	var fullSize = 1 / (ascender - descender);
	var fullVertical = 1 - ascender;
	var newCapitalMiddle = ((ascender - newBaseline) / 2) + newBaseline;
	var newFullMiddle = ((ascender - descender) / 2) + descender;
	return {
		capital: A3($mdgriffith$elm_ui$Internal$Model$adjust, capitalSize, ascender - newBaseline, capitalVertical),
		full: A3($mdgriffith$elm_ui$Internal$Model$adjust, fullSize, ascender - descender, fullVertical)
	};
};
var $mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules = function (converted) {
	return _Utils_Tuple2(
		_List_fromArray(
			[
				_Utils_Tuple2('display', 'block')
			]),
		_List_fromArray(
			[
				_Utils_Tuple2('display', 'inline-block'),
				_Utils_Tuple2(
				'line-height',
				$elm$core$String$fromFloat(converted.height)),
				_Utils_Tuple2(
				'vertical-align',
				$elm$core$String$fromFloat(converted.vertical) + 'em'),
				_Utils_Tuple2(
				'font-size',
				$elm$core$String$fromFloat(converted.size) + 'em')
			]));
};
var $mdgriffith$elm_ui$Internal$Model$typefaceAdjustment = function (typefaces) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (face, found) {
				if (found.$ === 'Nothing') {
					if (face.$ === 'FontWith') {
						var _with = face.a;
						var _v2 = _with.adjustment;
						if (_v2.$ === 'Nothing') {
							return found;
						} else {
							var adjustment = _v2.a;
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									$mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules(
										function ($) {
											return $.full;
										}(
											$mdgriffith$elm_ui$Internal$Model$convertAdjustment(adjustment))),
									$mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules(
										function ($) {
											return $.capital;
										}(
											$mdgriffith$elm_ui$Internal$Model$convertAdjustment(adjustment)))));
						}
					} else {
						return found;
					}
				} else {
					return found;
				}
			}),
		$elm$core$Maybe$Nothing,
		typefaces);
};
var $mdgriffith$elm_ui$Internal$Model$renderTopLevelValues = function (rules) {
	var withImport = function (font) {
		if (font.$ === 'ImportFont') {
			var url = font.b;
			return $elm$core$Maybe$Just('@import url(\'' + (url + '\');'));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	};
	var fontImports = function (_v2) {
		var name = _v2.a;
		var typefaces = _v2.b;
		var imports = A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$filterMap, withImport, typefaces));
		return imports;
	};
	var allNames = A2($elm$core$List$map, $elm$core$Tuple$first, rules);
	var fontAdjustments = function (_v1) {
		var name = _v1.a;
		var typefaces = _v1.b;
		var _v0 = $mdgriffith$elm_ui$Internal$Model$typefaceAdjustment(typefaces);
		if (_v0.$ === 'Nothing') {
			return A2(
				$elm$core$String$join,
				'',
				A2(
					$elm$core$List$map,
					$mdgriffith$elm_ui$Internal$Model$renderNullAdjustmentRule(name),
					allNames));
		} else {
			var adjustment = _v0.a;
			return A2(
				$elm$core$String$join,
				'',
				A2(
					$elm$core$List$map,
					A2($mdgriffith$elm_ui$Internal$Model$renderFontAdjustmentRule, name, adjustment),
					allNames));
		}
	};
	return _Utils_ap(
		A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$map, fontImports, rules)),
		A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$map, fontAdjustments, rules)));
};
var $mdgriffith$elm_ui$Internal$Model$topLevelValue = function (rule) {
	if (rule.$ === 'FontFamily') {
		var name = rule.a;
		var typefaces = rule.b;
		return $elm$core$Maybe$Just(
			_Utils_Tuple2(name, typefaces));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$toStyleSheetString = F2(
	function (options, stylesheet) {
		var combine = F2(
			function (style, rendered) {
				return {
					rules: _Utils_ap(
						rendered.rules,
						A3($mdgriffith$elm_ui$Internal$Model$renderStyleRule, options, style, $elm$core$Maybe$Nothing)),
					topLevel: function () {
						var _v1 = $mdgriffith$elm_ui$Internal$Model$topLevelValue(style);
						if (_v1.$ === 'Nothing') {
							return rendered.topLevel;
						} else {
							var topLevel = _v1.a;
							return A2($elm$core$List$cons, topLevel, rendered.topLevel);
						}
					}()
				};
			});
		var _v0 = A3(
			$elm$core$List$foldl,
			combine,
			{rules: _List_Nil, topLevel: _List_Nil},
			stylesheet);
		var topLevel = _v0.topLevel;
		var rules = _v0.rules;
		return _Utils_ap(
			$mdgriffith$elm_ui$Internal$Model$renderTopLevelValues(topLevel),
			$elm$core$String$concat(rules));
	});
var $mdgriffith$elm_ui$Internal$Model$toStyleSheet = F2(
	function (options, styleSheet) {
		var _v0 = options.mode;
		switch (_v0.$) {
			case 'Layout':
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'div',
					_List_Nil,
					_List_fromArray(
						[
							A3(
							$elm$virtual_dom$VirtualDom$node,
							'style',
							_List_Nil,
							_List_fromArray(
								[
									$elm$virtual_dom$VirtualDom$text(
									A2($mdgriffith$elm_ui$Internal$Model$toStyleSheetString, options, styleSheet))
								]))
						]));
			case 'NoStaticStyleSheet':
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'div',
					_List_Nil,
					_List_fromArray(
						[
							A3(
							$elm$virtual_dom$VirtualDom$node,
							'style',
							_List_Nil,
							_List_fromArray(
								[
									$elm$virtual_dom$VirtualDom$text(
									A2($mdgriffith$elm_ui$Internal$Model$toStyleSheetString, options, styleSheet))
								]))
						]));
			default:
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'elm-ui-rules',
					_List_fromArray(
						[
							A2(
							$elm$virtual_dom$VirtualDom$property,
							'rules',
							A2($mdgriffith$elm_ui$Internal$Model$encodeStyles, options, styleSheet))
						]),
					_List_Nil);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$embedKeyed = F4(
	function (_static, opts, styles, children) {
		var dynamicStyleSheet = A2(
			$mdgriffith$elm_ui$Internal$Model$toStyleSheet,
			opts,
			A3(
				$elm$core$List$foldl,
				$mdgriffith$elm_ui$Internal$Model$reduceStyles,
				_Utils_Tuple2(
					$elm$core$Set$empty,
					$mdgriffith$elm_ui$Internal$Model$renderFocusStyle(opts.focus)),
				styles).b);
		return _static ? A2(
			$elm$core$List$cons,
			_Utils_Tuple2(
				'static-stylesheet',
				$mdgriffith$elm_ui$Internal$Model$staticRoot(opts)),
			A2(
				$elm$core$List$cons,
				_Utils_Tuple2('dynamic-stylesheet', dynamicStyleSheet),
				children)) : A2(
			$elm$core$List$cons,
			_Utils_Tuple2('dynamic-stylesheet', dynamicStyleSheet),
			children);
	});
var $mdgriffith$elm_ui$Internal$Model$embedWith = F4(
	function (_static, opts, styles, children) {
		var dynamicStyleSheet = A2(
			$mdgriffith$elm_ui$Internal$Model$toStyleSheet,
			opts,
			A3(
				$elm$core$List$foldl,
				$mdgriffith$elm_ui$Internal$Model$reduceStyles,
				_Utils_Tuple2(
					$elm$core$Set$empty,
					$mdgriffith$elm_ui$Internal$Model$renderFocusStyle(opts.focus)),
				styles).b);
		return _static ? A2(
			$elm$core$List$cons,
			$mdgriffith$elm_ui$Internal$Model$staticRoot(opts),
			A2($elm$core$List$cons, dynamicStyleSheet, children)) : A2($elm$core$List$cons, dynamicStyleSheet, children);
	});
var $mdgriffith$elm_ui$Internal$Flag$heightBetween = $mdgriffith$elm_ui$Internal$Flag$flag(45);
var $mdgriffith$elm_ui$Internal$Flag$heightFill = $mdgriffith$elm_ui$Internal$Flag$flag(37);
var $elm$virtual_dom$VirtualDom$keyedNode = function (tag) {
	return _VirtualDom_keyedNode(
		_VirtualDom_noScript(tag));
};
var $elm$html$Html$p = _VirtualDom_node('p');
var $mdgriffith$elm_ui$Internal$Flag$present = F2(
	function (myFlag, _v0) {
		var fieldOne = _v0.a;
		var fieldTwo = _v0.b;
		if (myFlag.$ === 'Flag') {
			var first = myFlag.a;
			return _Utils_eq(first & fieldOne, first);
		} else {
			var second = myFlag.a;
			return _Utils_eq(second & fieldTwo, second);
		}
	});
var $elm$html$Html$s = _VirtualDom_node('s');
var $elm$html$Html$u = _VirtualDom_node('u');
var $mdgriffith$elm_ui$Internal$Flag$widthBetween = $mdgriffith$elm_ui$Internal$Flag$flag(44);
var $mdgriffith$elm_ui$Internal$Flag$widthFill = $mdgriffith$elm_ui$Internal$Flag$flag(39);
var $mdgriffith$elm_ui$Internal$Model$finalizeNode = F6(
	function (has, node, attributes, children, embedMode, parentContext) {
		var createNode = F2(
			function (nodeName, attrs) {
				if (children.$ === 'Keyed') {
					var keyed = children.a;
					return A3(
						$elm$virtual_dom$VirtualDom$keyedNode,
						nodeName,
						attrs,
						function () {
							switch (embedMode.$) {
								case 'NoStyleSheet':
									return keyed;
								case 'OnlyDynamic':
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedKeyed, false, opts, styles, keyed);
								default:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedKeyed, true, opts, styles, keyed);
							}
						}());
				} else {
					var unkeyed = children.a;
					return A2(
						function () {
							switch (nodeName) {
								case 'div':
									return $elm$html$Html$div;
								case 'p':
									return $elm$html$Html$p;
								default:
									return $elm$virtual_dom$VirtualDom$node(nodeName);
							}
						}(),
						attrs,
						function () {
							switch (embedMode.$) {
								case 'NoStyleSheet':
									return unkeyed;
								case 'OnlyDynamic':
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedWith, false, opts, styles, unkeyed);
								default:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedWith, true, opts, styles, unkeyed);
							}
						}());
				}
			});
		var html = function () {
			switch (node.$) {
				case 'Generic':
					return A2(createNode, 'div', attributes);
				case 'NodeName':
					var nodeName = node.a;
					return A2(createNode, nodeName, attributes);
				default:
					var nodeName = node.a;
					var internal = node.b;
					return A3(
						$elm$virtual_dom$VirtualDom$node,
						nodeName,
						attributes,
						_List_fromArray(
							[
								A2(
								createNode,
								internal,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.single))
									]))
							]));
			}
		}();
		switch (parentContext.$) {
			case 'AsRow':
				return (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$widthFill, has) && (!A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$widthBetween, has))) ? html : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$alignRight, has) ? A2(
					$elm$html$Html$u,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.any, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.container, $mdgriffith$elm_ui$Internal$Style$classes.contentCenterY, $mdgriffith$elm_ui$Internal$Style$classes.alignContainerRight])))
						]),
					_List_fromArray(
						[html])) : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$centerX, has) ? A2(
					$elm$html$Html$s,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.any, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.container, $mdgriffith$elm_ui$Internal$Style$classes.contentCenterY, $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterX])))
						]),
					_List_fromArray(
						[html])) : html));
			case 'AsColumn':
				return (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$heightFill, has) && (!A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$heightBetween, has))) ? html : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$centerY, has) ? A2(
					$elm$html$Html$s,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.any, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.container, $mdgriffith$elm_ui$Internal$Style$classes.alignContainerCenterY])))
						]),
					_List_fromArray(
						[html])) : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$alignBottom, has) ? A2(
					$elm$html$Html$u,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.any, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.container, $mdgriffith$elm_ui$Internal$Style$classes.alignContainerBottom])))
						]),
					_List_fromArray(
						[html])) : html));
			default:
				return html;
		}
	});
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $mdgriffith$elm_ui$Internal$Model$textElementClasses = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.text + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.widthContent + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.heightContent)))));
var $mdgriffith$elm_ui$Internal$Model$textElement = function (str) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Model$textElementClasses)
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(str)
			]));
};
var $mdgriffith$elm_ui$Internal$Model$textElementFillClasses = $mdgriffith$elm_ui$Internal$Style$classes.any + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.text + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.widthFill + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.heightFill)))));
var $mdgriffith$elm_ui$Internal$Model$textElementFill = function (str) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Model$textElementFillClasses)
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(str)
			]));
};
var $mdgriffith$elm_ui$Internal$Model$createElement = F3(
	function (context, children, rendered) {
		var gatherKeyed = F2(
			function (_v8, _v9) {
				var key = _v8.a;
				var child = _v8.b;
				var htmls = _v9.a;
				var existingStyles = _v9.b;
				switch (child.$) {
					case 'Unstyled':
						var html = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									html(context)),
								htmls),
							existingStyles) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									html(context)),
								htmls),
							existingStyles);
					case 'Styled':
						var styled = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									A2(styled.html, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context)),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.styles : _Utils_ap(styled.styles, existingStyles)) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									A2(styled.html, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context)),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.styles : _Utils_ap(styled.styles, existingStyles));
					case 'Text':
						var str = child.a;
						return _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									_Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asEl) ? $mdgriffith$elm_ui$Internal$Model$textElementFill(str) : $mdgriffith$elm_ui$Internal$Model$textElement(str)),
								htmls),
							existingStyles);
					default:
						return _Utils_Tuple2(htmls, existingStyles);
				}
			});
		var gather = F2(
			function (child, _v6) {
				var htmls = _v6.a;
				var existingStyles = _v6.b;
				switch (child.$) {
					case 'Unstyled':
						var html = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								html(context),
								htmls),
							existingStyles) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								html(context),
								htmls),
							existingStyles);
					case 'Styled':
						var styled = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								A2(styled.html, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.styles : _Utils_ap(styled.styles, existingStyles)) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								A2(styled.html, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.styles : _Utils_ap(styled.styles, existingStyles));
					case 'Text':
						var str = child.a;
						return _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asEl) ? $mdgriffith$elm_ui$Internal$Model$textElementFill(str) : $mdgriffith$elm_ui$Internal$Model$textElement(str),
								htmls),
							existingStyles);
					default:
						return _Utils_Tuple2(htmls, existingStyles);
				}
			});
		if (children.$ === 'Keyed') {
			var keyedChildren = children.a;
			var _v1 = A3(
				$elm$core$List$foldr,
				gatherKeyed,
				_Utils_Tuple2(_List_Nil, _List_Nil),
				keyedChildren);
			var keyed = _v1.a;
			var styles = _v1.b;
			var newStyles = $elm$core$List$isEmpty(styles) ? rendered.styles : _Utils_ap(rendered.styles, styles);
			if (!newStyles.b) {
				return $mdgriffith$elm_ui$Internal$Model$Unstyled(
					A5(
						$mdgriffith$elm_ui$Internal$Model$finalizeNode,
						rendered.has,
						rendered.node,
						rendered.attributes,
						$mdgriffith$elm_ui$Internal$Model$Keyed(
							A3($mdgriffith$elm_ui$Internal$Model$addKeyedChildren, 'nearby-element-pls', keyed, rendered.children)),
						$mdgriffith$elm_ui$Internal$Model$NoStyleSheet));
			} else {
				var allStyles = newStyles;
				return $mdgriffith$elm_ui$Internal$Model$Styled(
					{
						html: A4(
							$mdgriffith$elm_ui$Internal$Model$finalizeNode,
							rendered.has,
							rendered.node,
							rendered.attributes,
							$mdgriffith$elm_ui$Internal$Model$Keyed(
								A3($mdgriffith$elm_ui$Internal$Model$addKeyedChildren, 'nearby-element-pls', keyed, rendered.children))),
						styles: allStyles
					});
			}
		} else {
			var unkeyedChildren = children.a;
			var _v3 = A3(
				$elm$core$List$foldr,
				gather,
				_Utils_Tuple2(_List_Nil, _List_Nil),
				unkeyedChildren);
			var unkeyed = _v3.a;
			var styles = _v3.b;
			var newStyles = $elm$core$List$isEmpty(styles) ? rendered.styles : _Utils_ap(rendered.styles, styles);
			if (!newStyles.b) {
				return $mdgriffith$elm_ui$Internal$Model$Unstyled(
					A5(
						$mdgriffith$elm_ui$Internal$Model$finalizeNode,
						rendered.has,
						rendered.node,
						rendered.attributes,
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							A2($mdgriffith$elm_ui$Internal$Model$addChildren, unkeyed, rendered.children)),
						$mdgriffith$elm_ui$Internal$Model$NoStyleSheet));
			} else {
				var allStyles = newStyles;
				return $mdgriffith$elm_ui$Internal$Model$Styled(
					{
						html: A4(
							$mdgriffith$elm_ui$Internal$Model$finalizeNode,
							rendered.has,
							rendered.node,
							rendered.attributes,
							$mdgriffith$elm_ui$Internal$Model$Unkeyed(
								A2($mdgriffith$elm_ui$Internal$Model$addChildren, unkeyed, rendered.children))),
						styles: allStyles
					});
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Single = F3(
	function (a, b, c) {
		return {$: 'Single', a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$Transform = function (a) {
	return {$: 'Transform', a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$core$Bitwise$or = _Bitwise_or;
var $mdgriffith$elm_ui$Internal$Flag$add = F2(
	function (myFlag, _v0) {
		var one = _v0.a;
		var two = _v0.b;
		if (myFlag.$ === 'Flag') {
			var first = myFlag.a;
			return A2($mdgriffith$elm_ui$Internal$Flag$Field, first | one, two);
		} else {
			var second = myFlag.a;
			return A2($mdgriffith$elm_ui$Internal$Flag$Field, one, second | two);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$ChildrenBehind = function (a) {
	return {$: 'ChildrenBehind', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront = F2(
	function (a, b) {
		return {$: 'ChildrenBehindAndInFront', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$ChildrenInFront = function (a) {
	return {$: 'ChildrenInFront', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$nearbyElement = F2(
	function (location, elem) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(
					function () {
						switch (location.$) {
							case 'Above':
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.above]));
							case 'Below':
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.below]));
							case 'OnRight':
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.onRight]));
							case 'OnLeft':
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.onLeft]));
							case 'InFront':
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.inFront]));
							default:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.nearby, $mdgriffith$elm_ui$Internal$Style$classes.single, $mdgriffith$elm_ui$Internal$Style$classes.behind]));
						}
					}())
				]),
			_List_fromArray(
				[
					function () {
					switch (elem.$) {
						case 'Empty':
							return $elm$virtual_dom$VirtualDom$text('');
						case 'Text':
							var str = elem.a;
							return $mdgriffith$elm_ui$Internal$Model$textElement(str);
						case 'Unstyled':
							var html = elem.a;
							return html($mdgriffith$elm_ui$Internal$Model$asEl);
						default:
							var styled = elem.a;
							return A2(styled.html, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, $mdgriffith$elm_ui$Internal$Model$asEl);
					}
				}()
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$addNearbyElement = F3(
	function (location, elem, existing) {
		var nearby = A2($mdgriffith$elm_ui$Internal$Model$nearbyElement, location, elem);
		switch (existing.$) {
			case 'NoNearbyChildren':
				if (location.$ === 'Behind') {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenBehind(
						_List_fromArray(
							[nearby]));
				} else {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenInFront(
						_List_fromArray(
							[nearby]));
				}
			case 'ChildrenBehind':
				var existingBehind = existing.a;
				if (location.$ === 'Behind') {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenBehind(
						A2($elm$core$List$cons, nearby, existingBehind));
				} else {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						existingBehind,
						_List_fromArray(
							[nearby]));
				}
			case 'ChildrenInFront':
				var existingInFront = existing.a;
				if (location.$ === 'Behind') {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						_List_fromArray(
							[nearby]),
						existingInFront);
				} else {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenInFront(
						A2($elm$core$List$cons, nearby, existingInFront));
				}
			default:
				var existingBehind = existing.a;
				var existingInFront = existing.b;
				if (location.$ === 'Behind') {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						A2($elm$core$List$cons, nearby, existingBehind),
						existingInFront);
				} else {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						existingBehind,
						A2($elm$core$List$cons, nearby, existingInFront));
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Embedded = F2(
	function (a, b) {
		return {$: 'Embedded', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$NodeName = function (a) {
	return {$: 'NodeName', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$addNodeName = F2(
	function (newNode, old) {
		switch (old.$) {
			case 'Generic':
				return $mdgriffith$elm_ui$Internal$Model$NodeName(newNode);
			case 'NodeName':
				var name = old.a;
				return A2($mdgriffith$elm_ui$Internal$Model$Embedded, name, newNode);
			default:
				var x = old.a;
				var y = old.b;
				return A2($mdgriffith$elm_ui$Internal$Model$Embedded, x, y);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$alignXName = function (align) {
	switch (align.$) {
		case 'Left':
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedHorizontally + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignLeft);
		case 'Right':
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedHorizontally + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignRight);
		default:
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedHorizontally + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignCenterX);
	}
};
var $mdgriffith$elm_ui$Internal$Model$alignYName = function (align) {
	switch (align.$) {
		case 'Top':
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedVertically + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignTop);
		case 'Bottom':
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedVertically + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignBottom);
		default:
			return $mdgriffith$elm_ui$Internal$Style$classes.alignedVertically + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.alignCenterY);
	}
};
var $elm$virtual_dom$VirtualDom$attribute = F2(
	function (key, value) {
		return A2(
			_VirtualDom_attribute,
			_VirtualDom_noOnOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $mdgriffith$elm_ui$Internal$Model$FullTransform = F4(
	function (a, b, c, d) {
		return {$: 'FullTransform', a: a, b: b, c: c, d: d};
	});
var $mdgriffith$elm_ui$Internal$Model$Moved = function (a) {
	return {$: 'Moved', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$composeTransformation = F2(
	function (transform, component) {
		switch (transform.$) {
			case 'Untransformed':
				switch (component.$) {
					case 'MoveX':
						var x = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, 0, 0));
					case 'MoveY':
						var y = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(0, y, 0));
					case 'MoveZ':
						var z = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(0, 0, z));
					case 'MoveXYZ':
						var xyz = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(xyz);
					case 'Rotate':
						var xyz = component.a;
						var angle = component.b;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(0, 0, 0),
							_Utils_Tuple3(1, 1, 1),
							xyz,
							angle);
					default:
						var xyz = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(0, 0, 0),
							xyz,
							_Utils_Tuple3(0, 0, 1),
							0);
				}
			case 'Moved':
				var moved = transform.a;
				var x = moved.a;
				var y = moved.b;
				var z = moved.c;
				switch (component.$) {
					case 'MoveX':
						var newX = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(newX, y, z));
					case 'MoveY':
						var newY = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, newY, z));
					case 'MoveZ':
						var newZ = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, y, newZ));
					case 'MoveXYZ':
						var xyz = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(xyz);
					case 'Rotate':
						var xyz = component.a;
						var angle = component.b;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							moved,
							_Utils_Tuple3(1, 1, 1),
							xyz,
							angle);
					default:
						var scale = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							moved,
							scale,
							_Utils_Tuple3(0, 0, 1),
							0);
				}
			default:
				var moved = transform.a;
				var x = moved.a;
				var y = moved.b;
				var z = moved.c;
				var scaled = transform.b;
				var origin = transform.c;
				var angle = transform.d;
				switch (component.$) {
					case 'MoveX':
						var newX = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(newX, y, z),
							scaled,
							origin,
							angle);
					case 'MoveY':
						var newY = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(x, newY, z),
							scaled,
							origin,
							angle);
					case 'MoveZ':
						var newZ = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(x, y, newZ),
							scaled,
							origin,
							angle);
					case 'MoveXYZ':
						var newMove = component.a;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, newMove, scaled, origin, angle);
					case 'Rotate':
						var newOrigin = component.a;
						var newAngle = component.b;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, moved, scaled, newOrigin, newAngle);
					default:
						var newScale = component.a;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, moved, newScale, origin, angle);
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Flag$height = $mdgriffith$elm_ui$Internal$Flag$flag(7);
var $mdgriffith$elm_ui$Internal$Flag$heightContent = $mdgriffith$elm_ui$Internal$Flag$flag(36);
var $mdgriffith$elm_ui$Internal$Flag$merge = F2(
	function (_v0, _v1) {
		var one = _v0.a;
		var two = _v0.b;
		var three = _v1.a;
		var four = _v1.b;
		return A2($mdgriffith$elm_ui$Internal$Flag$Field, one | three, two | four);
	});
var $mdgriffith$elm_ui$Internal$Flag$none = A2($mdgriffith$elm_ui$Internal$Flag$Field, 0, 0);
var $mdgriffith$elm_ui$Internal$Model$renderHeight = function (h) {
	switch (h.$) {
		case 'Px':
			var px = h.a;
			var val = $elm$core$String$fromInt(px);
			var name = 'height-px-' + val;
			return _Utils_Tuple3(
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Style$classes.heightExact + (' ' + name),
				_List_fromArray(
					[
						A3($mdgriffith$elm_ui$Internal$Model$Single, name, 'height', val + 'px')
					]));
		case 'Content':
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightContent, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.heightContent,
				_List_Nil);
		case 'Fill':
			var portion = h.a;
			return (portion === 1) ? _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.heightFill,
				_List_Nil) : _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.heightFillPortion + (' height-fill-' + $elm$core$String$fromInt(portion)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						$mdgriffith$elm_ui$Internal$Style$classes.any + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.column + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
							'height-fill-' + $elm$core$String$fromInt(portion))))),
						'flex-grow',
						$elm$core$String$fromInt(portion * 100000))
					]));
		case 'Min':
			var minSize = h.a;
			var len = h.b;
			var cls = 'min-height-' + $elm$core$String$fromInt(minSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'min-height',
				$elm$core$String$fromInt(minSize) + 'px !important');
			var _v1 = $mdgriffith$elm_ui$Internal$Model$renderHeight(len);
			var newFlag = _v1.a;
			var newAttrs = _v1.b;
			var newStyle = _v1.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
		default:
			var maxSize = h.a;
			var len = h.b;
			var cls = 'max-height-' + $elm$core$String$fromInt(maxSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'max-height',
				$elm$core$String$fromInt(maxSize) + 'px');
			var _v2 = $mdgriffith$elm_ui$Internal$Model$renderHeight(len);
			var newFlag = _v2.a;
			var newAttrs = _v2.b;
			var newStyle = _v2.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
	}
};
var $mdgriffith$elm_ui$Internal$Flag$widthContent = $mdgriffith$elm_ui$Internal$Flag$flag(38);
var $mdgriffith$elm_ui$Internal$Model$renderWidth = function (w) {
	switch (w.$) {
		case 'Px':
			var px = w.a;
			return _Utils_Tuple3(
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Style$classes.widthExact + (' width-px-' + $elm$core$String$fromInt(px)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						'width-px-' + $elm$core$String$fromInt(px),
						'width',
						$elm$core$String$fromInt(px) + 'px')
					]));
		case 'Content':
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthContent, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.widthContent,
				_List_Nil);
		case 'Fill':
			var portion = w.a;
			return (portion === 1) ? _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.widthFill,
				_List_Nil) : _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.widthFillPortion + (' width-fill-' + $elm$core$String$fromInt(portion)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						$mdgriffith$elm_ui$Internal$Style$classes.any + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.row + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
							'width-fill-' + $elm$core$String$fromInt(portion))))),
						'flex-grow',
						$elm$core$String$fromInt(portion * 100000))
					]));
		case 'Min':
			var minSize = w.a;
			var len = w.b;
			var cls = 'min-width-' + $elm$core$String$fromInt(minSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'min-width',
				$elm$core$String$fromInt(minSize) + 'px');
			var _v1 = $mdgriffith$elm_ui$Internal$Model$renderWidth(len);
			var newFlag = _v1.a;
			var newAttrs = _v1.b;
			var newStyle = _v1.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
		default:
			var maxSize = w.a;
			var len = w.b;
			var cls = 'max-width-' + $elm$core$String$fromInt(maxSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'max-width',
				$elm$core$String$fromInt(maxSize) + 'px');
			var _v2 = $mdgriffith$elm_ui$Internal$Model$renderWidth(len);
			var newFlag = _v2.a;
			var newAttrs = _v2.b;
			var newStyle = _v2.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
	}
};
var $mdgriffith$elm_ui$Internal$Flag$borderWidth = $mdgriffith$elm_ui$Internal$Flag$flag(27);
var $mdgriffith$elm_ui$Internal$Model$skippable = F2(
	function (flag, style) {
		if (_Utils_eq(flag, $mdgriffith$elm_ui$Internal$Flag$borderWidth)) {
			if (style.$ === 'Single') {
				var val = style.c;
				switch (val) {
					case '0px':
						return true;
					case '1px':
						return true;
					case '2px':
						return true;
					case '3px':
						return true;
					case '4px':
						return true;
					case '5px':
						return true;
					case '6px':
						return true;
					default:
						return false;
				}
			} else {
				return false;
			}
		} else {
			switch (style.$) {
				case 'FontSize':
					var i = style.a;
					return (i >= 8) && (i <= 32);
				case 'PaddingStyle':
					var name = style.a;
					var t = style.b;
					var r = style.c;
					var b = style.d;
					var l = style.e;
					return _Utils_eq(t, b) && (_Utils_eq(t, r) && (_Utils_eq(t, l) && ((t >= 0) && (t <= 24))));
				default:
					return false;
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Flag$width = $mdgriffith$elm_ui$Internal$Flag$flag(6);
var $mdgriffith$elm_ui$Internal$Flag$xAlign = $mdgriffith$elm_ui$Internal$Flag$flag(30);
var $mdgriffith$elm_ui$Internal$Flag$yAlign = $mdgriffith$elm_ui$Internal$Flag$flag(29);
var $mdgriffith$elm_ui$Internal$Model$gatherAttrRecursive = F8(
	function (classes, node, has, transform, styles, attrs, children, elementAttrs) {
		gatherAttrRecursive:
		while (true) {
			if (!elementAttrs.b) {
				var _v1 = $mdgriffith$elm_ui$Internal$Model$transformClass(transform);
				if (_v1.$ === 'Nothing') {
					return {
						attributes: A2(
							$elm$core$List$cons,
							$elm$html$Html$Attributes$class(classes),
							attrs),
						children: children,
						has: has,
						node: node,
						styles: styles
					};
				} else {
					var _class = _v1.a;
					return {
						attributes: A2(
							$elm$core$List$cons,
							$elm$html$Html$Attributes$class(classes + (' ' + _class)),
							attrs),
						children: children,
						has: has,
						node: node,
						styles: A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$Transform(transform),
							styles)
					};
				}
			} else {
				var attribute = elementAttrs.a;
				var remaining = elementAttrs.b;
				switch (attribute.$) {
					case 'NoAttribute':
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = styles,
							$temp$attrs = attrs,
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 'Class':
						var flag = attribute.a;
						var exactClassName = attribute.b;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, flag, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = exactClassName + (' ' + classes),
								$temp$node = node,
								$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
					case 'Attr':
						var actualAttribute = attribute.a;
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = styles,
							$temp$attrs = A2($elm$core$List$cons, actualAttribute, attrs),
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 'StyleClass':
						var flag = attribute.a;
						var style = attribute.b;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, flag, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							if (A2($mdgriffith$elm_ui$Internal$Model$skippable, flag, style)) {
								var $temp$classes = $mdgriffith$elm_ui$Internal$Model$getStyleName(style) + (' ' + classes),
									$temp$node = node,
									$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							} else {
								var $temp$classes = $mdgriffith$elm_ui$Internal$Model$getStyleName(style) + (' ' + classes),
									$temp$node = node,
									$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
									$temp$transform = transform,
									$temp$styles = A2($elm$core$List$cons, style, styles),
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							}
						}
					case 'TransformComponent':
						var flag = attribute.a;
						var component = attribute.b;
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
							$temp$transform = A2($mdgriffith$elm_ui$Internal$Model$composeTransformation, transform, component),
							$temp$styles = styles,
							$temp$attrs = attrs,
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 'Width':
						var width = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$width, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							switch (width.$) {
								case 'Px':
									var px = width.a;
									var $temp$classes = ($mdgriffith$elm_ui$Internal$Style$classes.widthExact + (' width-px-' + $elm$core$String$fromInt(px))) + (' ' + classes),
										$temp$node = node,
										$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has),
										$temp$transform = transform,
										$temp$styles = A2(
										$elm$core$List$cons,
										A3(
											$mdgriffith$elm_ui$Internal$Model$Single,
											'width-px-' + $elm$core$String$fromInt(px),
											'width',
											$elm$core$String$fromInt(px) + 'px'),
										styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 'Content':
									var $temp$classes = classes + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.widthContent),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$add,
										$mdgriffith$elm_ui$Internal$Flag$widthContent,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 'Fill':
									var portion = width.a;
									if (portion === 1) {
										var $temp$classes = classes + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.widthFill),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$widthFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.widthFillPortion + (' width-fill-' + $elm$core$String$fromInt(portion)))),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$widthFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
											$temp$transform = transform,
											$temp$styles = A2(
											$elm$core$List$cons,
											A3(
												$mdgriffith$elm_ui$Internal$Model$Single,
												$mdgriffith$elm_ui$Internal$Style$classes.any + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.row + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
													'width-fill-' + $elm$core$String$fromInt(portion))))),
												'flex-grow',
												$elm$core$String$fromInt(portion * 100000)),
											styles),
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								default:
									var _v4 = $mdgriffith$elm_ui$Internal$Model$renderWidth(width);
									var addToFlags = _v4.a;
									var newClass = _v4.b;
									var newStyles = _v4.c;
									var $temp$classes = classes + (' ' + newClass),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$merge,
										addToFlags,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
										$temp$transform = transform,
										$temp$styles = _Utils_ap(newStyles, styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
							}
						}
					case 'Height':
						var height = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$height, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							switch (height.$) {
								case 'Px':
									var px = height.a;
									var val = $elm$core$String$fromInt(px) + 'px';
									var name = 'height-px-' + val;
									var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.heightExact + (' ' + (name + (' ' + classes))),
										$temp$node = node,
										$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has),
										$temp$transform = transform,
										$temp$styles = A2(
										$elm$core$List$cons,
										A3($mdgriffith$elm_ui$Internal$Model$Single, name, 'height ', val),
										styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 'Content':
									var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.heightContent + (' ' + classes),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$add,
										$mdgriffith$elm_ui$Internal$Flag$heightContent,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 'Fill':
									var portion = height.a;
									if (portion === 1) {
										var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.heightFill + (' ' + classes),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$heightFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.heightFillPortion + (' height-fill-' + $elm$core$String$fromInt(portion)))),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$heightFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
											$temp$transform = transform,
											$temp$styles = A2(
											$elm$core$List$cons,
											A3(
												$mdgriffith$elm_ui$Internal$Model$Single,
												$mdgriffith$elm_ui$Internal$Style$classes.any + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.column + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
													'height-fill-' + $elm$core$String$fromInt(portion))))),
												'flex-grow',
												$elm$core$String$fromInt(portion * 100000)),
											styles),
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								default:
									var _v6 = $mdgriffith$elm_ui$Internal$Model$renderHeight(height);
									var addToFlags = _v6.a;
									var newClass = _v6.b;
									var newStyles = _v6.c;
									var $temp$classes = classes + (' ' + newClass),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$merge,
										addToFlags,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
										$temp$transform = transform,
										$temp$styles = _Utils_ap(newStyles, styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
							}
						}
					case 'Describe':
						var description = attribute.a;
						switch (description.$) {
							case 'Main':
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'main', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'Navigation':
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'nav', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'ContentInfo':
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'footer', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'Complementary':
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'aside', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'Heading':
								var i = description.a;
								if (i <= 1) {
									var $temp$classes = classes,
										$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'h1', node),
										$temp$has = has,
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								} else {
									if (i < 7) {
										var $temp$classes = classes,
											$temp$node = A2(
											$mdgriffith$elm_ui$Internal$Model$addNodeName,
											'h' + $elm$core$String$fromInt(i),
											node),
											$temp$has = has,
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes,
											$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'h6', node),
											$temp$has = has,
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								}
							case 'Paragraph':
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'Button':
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'role', 'button'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'Label':
								var label = description.a;
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-label', label),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 'LivePolite':
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-live', 'polite'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							default:
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-live', 'assertive'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
						}
					case 'Nearby':
						var location = attribute.a;
						var elem = attribute.b;
						var newStyles = function () {
							switch (elem.$) {
								case 'Empty':
									return styles;
								case 'Text':
									var str = elem.a;
									return styles;
								case 'Unstyled':
									var html = elem.a;
									return styles;
								default:
									var styled = elem.a;
									return _Utils_ap(styles, styled.styles);
							}
						}();
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = newStyles,
							$temp$attrs = attrs,
							$temp$children = A3($mdgriffith$elm_ui$Internal$Model$addNearbyElement, location, elem, children),
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 'AlignX':
						var x = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$xAlign, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = $mdgriffith$elm_ui$Internal$Model$alignXName(x) + (' ' + classes),
								$temp$node = node,
								$temp$has = function (flags) {
								switch (x.$) {
									case 'CenterX':
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$centerX, flags);
									case 'Right':
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$alignRight, flags);
									default:
										return flags;
								}
							}(
								A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$xAlign, has)),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
					default:
						var y = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$yAlign, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = $mdgriffith$elm_ui$Internal$Model$alignYName(y) + (' ' + classes),
								$temp$node = node,
								$temp$has = function (flags) {
								switch (y.$) {
									case 'CenterY':
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$centerY, flags);
									case 'Bottom':
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$alignBottom, flags);
									default:
										return flags;
								}
							}(
								A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$yAlign, has)),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
				}
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Untransformed = {$: 'Untransformed'};
var $mdgriffith$elm_ui$Internal$Model$untransformed = $mdgriffith$elm_ui$Internal$Model$Untransformed;
var $mdgriffith$elm_ui$Internal$Model$element = F4(
	function (context, node, attributes, children) {
		return A3(
			$mdgriffith$elm_ui$Internal$Model$createElement,
			context,
			children,
			A8(
				$mdgriffith$elm_ui$Internal$Model$gatherAttrRecursive,
				$mdgriffith$elm_ui$Internal$Model$contextClasses(context),
				node,
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Model$untransformed,
				_List_Nil,
				_List_Nil,
				$mdgriffith$elm_ui$Internal$Model$NoNearbyChildren,
				$elm$core$List$reverse(attributes)));
	});
var $mdgriffith$elm_ui$Internal$Model$AllowHover = {$: 'AllowHover'};
var $mdgriffith$elm_ui$Internal$Model$Layout = {$: 'Layout'};
var $mdgriffith$elm_ui$Internal$Model$Rgba = F4(
	function (a, b, c, d) {
		return {$: 'Rgba', a: a, b: b, c: c, d: d};
	});
var $mdgriffith$elm_ui$Internal$Model$focusDefaultStyle = {
	backgroundColor: $elm$core$Maybe$Nothing,
	borderColor: $elm$core$Maybe$Nothing,
	shadow: $elm$core$Maybe$Just(
		{
			blur: 0,
			color: A4($mdgriffith$elm_ui$Internal$Model$Rgba, 155 / 255, 203 / 255, 1, 1),
			offset: _Utils_Tuple2(0, 0),
			size: 3
		})
};
var $mdgriffith$elm_ui$Internal$Model$optionsToRecord = function (options) {
	var combine = F2(
		function (opt, record) {
			switch (opt.$) {
				case 'HoverOption':
					var hoverable = opt.a;
					var _v4 = record.hover;
					if (_v4.$ === 'Nothing') {
						return _Utils_update(
							record,
							{
								hover: $elm$core$Maybe$Just(hoverable)
							});
					} else {
						return record;
					}
				case 'FocusStyleOption':
					var focusStyle = opt.a;
					var _v5 = record.focus;
					if (_v5.$ === 'Nothing') {
						return _Utils_update(
							record,
							{
								focus: $elm$core$Maybe$Just(focusStyle)
							});
					} else {
						return record;
					}
				default:
					var renderMode = opt.a;
					var _v6 = record.mode;
					if (_v6.$ === 'Nothing') {
						return _Utils_update(
							record,
							{
								mode: $elm$core$Maybe$Just(renderMode)
							});
					} else {
						return record;
					}
			}
		});
	var andFinally = function (record) {
		return {
			focus: function () {
				var _v0 = record.focus;
				if (_v0.$ === 'Nothing') {
					return $mdgriffith$elm_ui$Internal$Model$focusDefaultStyle;
				} else {
					var focusable = _v0.a;
					return focusable;
				}
			}(),
			hover: function () {
				var _v1 = record.hover;
				if (_v1.$ === 'Nothing') {
					return $mdgriffith$elm_ui$Internal$Model$AllowHover;
				} else {
					var hoverable = _v1.a;
					return hoverable;
				}
			}(),
			mode: function () {
				var _v2 = record.mode;
				if (_v2.$ === 'Nothing') {
					return $mdgriffith$elm_ui$Internal$Model$Layout;
				} else {
					var actualMode = _v2.a;
					return actualMode;
				}
			}()
		};
	};
	return andFinally(
		A3(
			$elm$core$List$foldr,
			combine,
			{focus: $elm$core$Maybe$Nothing, hover: $elm$core$Maybe$Nothing, mode: $elm$core$Maybe$Nothing},
			options));
};
var $mdgriffith$elm_ui$Internal$Model$toHtml = F2(
	function (mode, el) {
		switch (el.$) {
			case 'Unstyled':
				var html = el.a;
				return html($mdgriffith$elm_ui$Internal$Model$asEl);
			case 'Styled':
				var styles = el.a.styles;
				var html = el.a.html;
				return A2(
					html,
					mode(styles),
					$mdgriffith$elm_ui$Internal$Model$asEl);
			case 'Text':
				var text = el.a;
				return $mdgriffith$elm_ui$Internal$Model$textElement(text);
			default:
				return $mdgriffith$elm_ui$Internal$Model$textElement('');
		}
	});
var $mdgriffith$elm_ui$Internal$Model$renderRoot = F3(
	function (optionList, attributes, child) {
		var options = $mdgriffith$elm_ui$Internal$Model$optionsToRecord(optionList);
		var embedStyle = function () {
			var _v0 = options.mode;
			if (_v0.$ === 'NoStaticStyleSheet') {
				return $mdgriffith$elm_ui$Internal$Model$OnlyDynamic(options);
			} else {
				return $mdgriffith$elm_ui$Internal$Model$StaticRootAndDynamic(options);
			}
		}();
		return A2(
			$mdgriffith$elm_ui$Internal$Model$toHtml,
			embedStyle,
			A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asEl,
				$mdgriffith$elm_ui$Internal$Model$div,
				attributes,
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(
					_List_fromArray(
						[child]))));
	});
var $mdgriffith$elm_ui$Internal$Model$Colored = F3(
	function (a, b, c) {
		return {$: 'Colored', a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$FontFamily = F2(
	function (a, b) {
		return {$: 'FontFamily', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$FontSize = function (a) {
	return {$: 'FontSize', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$SansSerif = {$: 'SansSerif'};
var $mdgriffith$elm_ui$Internal$Model$StyleClass = F2(
	function (a, b) {
		return {$: 'StyleClass', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Typeface = function (a) {
	return {$: 'Typeface', a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$bgColor = $mdgriffith$elm_ui$Internal$Flag$flag(8);
var $mdgriffith$elm_ui$Internal$Flag$fontColor = $mdgriffith$elm_ui$Internal$Flag$flag(14);
var $mdgriffith$elm_ui$Internal$Flag$fontFamily = $mdgriffith$elm_ui$Internal$Flag$flag(5);
var $mdgriffith$elm_ui$Internal$Flag$fontSize = $mdgriffith$elm_ui$Internal$Flag$flag(4);
var $mdgriffith$elm_ui$Internal$Model$formatColorClass = function (_v0) {
	var red = _v0.a;
	var green = _v0.b;
	var blue = _v0.c;
	var alpha = _v0.d;
	return $mdgriffith$elm_ui$Internal$Model$floatClass(red) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(green) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(blue) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(alpha))))));
};
var $elm$core$String$words = _String_words;
var $mdgriffith$elm_ui$Internal$Model$renderFontClassName = F2(
	function (font, current) {
		return _Utils_ap(
			current,
			function () {
				switch (font.$) {
					case 'Serif':
						return 'serif';
					case 'SansSerif':
						return 'sans-serif';
					case 'Monospace':
						return 'monospace';
					case 'Typeface':
						var name = font.a;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
					case 'ImportFont':
						var name = font.a;
						var url = font.b;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
					default:
						var name = font.a.name;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
				}
			}());
	});
var $mdgriffith$elm_ui$Internal$Model$rootStyle = function () {
	var families = _List_fromArray(
		[
			$mdgriffith$elm_ui$Internal$Model$Typeface('Open Sans'),
			$mdgriffith$elm_ui$Internal$Model$Typeface('Helvetica'),
			$mdgriffith$elm_ui$Internal$Model$Typeface('Verdana'),
			$mdgriffith$elm_ui$Internal$Model$SansSerif
		]);
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$bgColor,
			A3(
				$mdgriffith$elm_ui$Internal$Model$Colored,
				'bg-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(
					A4($mdgriffith$elm_ui$Internal$Model$Rgba, 1, 1, 1, 0)),
				'background-color',
				A4($mdgriffith$elm_ui$Internal$Model$Rgba, 1, 1, 1, 0))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontColor,
			A3(
				$mdgriffith$elm_ui$Internal$Model$Colored,
				'fc-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(
					A4($mdgriffith$elm_ui$Internal$Model$Rgba, 0, 0, 0, 1)),
				'color',
				A4($mdgriffith$elm_ui$Internal$Model$Rgba, 0, 0, 0, 1))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontSize,
			$mdgriffith$elm_ui$Internal$Model$FontSize(20)),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontFamily,
			A2(
				$mdgriffith$elm_ui$Internal$Model$FontFamily,
				A3($elm$core$List$foldl, $mdgriffith$elm_ui$Internal$Model$renderFontClassName, 'font-', families),
				families))
		]);
}();
var $mdgriffith$elm_ui$Element$layoutWith = F3(
	function (_v0, attrs, child) {
		var options = _v0.options;
		return A3(
			$mdgriffith$elm_ui$Internal$Model$renderRoot,
			options,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass(
					A2(
						$elm$core$String$join,
						' ',
						_List_fromArray(
							[$mdgriffith$elm_ui$Internal$Style$classes.root, $mdgriffith$elm_ui$Internal$Style$classes.any, $mdgriffith$elm_ui$Internal$Style$classes.single]))),
				_Utils_ap($mdgriffith$elm_ui$Internal$Model$rootStyle, attrs)),
			child);
	});
var $mdgriffith$elm_ui$Internal$Model$Empty = {$: 'Empty'};
var $mdgriffith$elm_ui$Element$none = $mdgriffith$elm_ui$Internal$Model$Empty;
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $author$project$Main$elmUiHackLayout = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'height', '0')
		]),
	_List_fromArray(
		[
			A3(
			$mdgriffith$elm_ui$Element$layoutWith,
			{
				options: _List_fromArray(
					[
						$mdgriffith$elm_ui$Element$focusStyle(
						{backgroundColor: $elm$core$Maybe$Nothing, borderColor: $elm$core$Maybe$Nothing, shadow: $elm$core$Maybe$Nothing})
					])
			},
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$htmlAttribute(
					$elm$html$Html$Attributes$id('hack'))
				]),
			$mdgriffith$elm_ui$Element$none)
		]));
var $mdgriffith$elm_ui$Internal$Model$Fill = function (a) {
	return {$: 'Fill', a: a};
};
var $mdgriffith$elm_ui$Element$fill = $mdgriffith$elm_ui$Internal$Model$Fill(1);
var $mdgriffith$elm_ui$Internal$Model$Height = function (a) {
	return {$: 'Height', a: a};
};
var $mdgriffith$elm_ui$Element$height = $mdgriffith$elm_ui$Internal$Model$Height;
var $elm$virtual_dom$VirtualDom$map = _VirtualDom_map;
var $elm$html$Html$map = $elm$virtual_dom$VirtualDom$map;
var $mdgriffith$elm_ui$Internal$Model$NoStaticStyleSheet = {$: 'NoStaticStyleSheet'};
var $mdgriffith$elm_ui$Internal$Model$RenderModeOption = function (a) {
	return {$: 'RenderModeOption', a: a};
};
var $mdgriffith$elm_ui$Element$noStaticStyleSheet = $mdgriffith$elm_ui$Internal$Model$RenderModeOption($mdgriffith$elm_ui$Internal$Model$NoStaticStyleSheet);
var $elm$html$Html$button = _VirtualDom_node('button');
var $elm$html$Html$node = $elm$virtual_dom$VirtualDom$node;
var $author$project$Dialog$dialogNode = F3(
	function (elementId, attr, content) {
		return A3(
			$elm$html$Html$node,
			'dialog',
			A2(
				$elm$core$List$cons,
				$elm$html$Html$Attributes$id(elementId),
				attr),
			content);
	});
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 'Normal', a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Dialog$view = F3(
	function (elementId, closeMsg, content) {
		return A3(
			$author$project$Dialog$dialogNode,
			elementId,
			_List_Nil,
			_List_fromArray(
				[
					content,
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 m-2'),
							$elm$html$Html$Events$onClick(closeMsg)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Close')
						]))
				]));
	});
var $author$project$Traveller$FocusInSidebar = function (a) {
	return {$: 'FocusInSidebar', a: a};
};
var $author$project$Traveller$SetHexSize = function (a) {
	return {$: 'SetHexSize', a: a};
};
var $author$project$Traveller$ToggleHexmap = {$: 'ToggleHexmap'};
var $author$project$Traveller$ViewObjectAnalysisDetail = function (a) {
	return {$: 'ViewObjectAnalysisDetail', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$Left = {$: 'Left'};
var $mdgriffith$elm_ui$Element$alignLeft = $mdgriffith$elm_ui$Internal$Model$AlignX($mdgriffith$elm_ui$Internal$Model$Left);
var $mdgriffith$elm_ui$Internal$Model$AlignY = function (a) {
	return {$: 'AlignY', a: a};
};
var $mdgriffith$elm_ui$Internal$Model$Top = {$: 'Top'};
var $mdgriffith$elm_ui$Element$alignTop = $mdgriffith$elm_ui$Internal$Model$AlignY($mdgriffith$elm_ui$Internal$Model$Top);
var $mdgriffith$elm_ui$Element$Background$color = function (clr) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$bgColor,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Colored,
			'bg-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(clr),
			'background-color',
			clr));
};
var $mdgriffith$elm_ui$Element$Font$color = function (fontColor) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$fontColor,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Colored,
			'fc-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(fontColor),
			'color',
			fontColor));
};
var $mdgriffith$elm_ui$Internal$Model$AsColumn = {$: 'AsColumn'};
var $mdgriffith$elm_ui$Internal$Model$asColumn = $mdgriffith$elm_ui$Internal$Model$AsColumn;
var $mdgriffith$elm_ui$Internal$Model$Content = {$: 'Content'};
var $mdgriffith$elm_ui$Element$shrink = $mdgriffith$elm_ui$Internal$Model$Content;
var $mdgriffith$elm_ui$Internal$Model$Width = function (a) {
	return {$: 'Width', a: a};
};
var $mdgriffith$elm_ui$Element$width = $mdgriffith$elm_ui$Internal$Model$Width;
var $mdgriffith$elm_ui$Element$column = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asColumn,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentTop + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.contentLeft)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $mdgriffith$elm_ui$Element$el = F2(
	function (attrs, child) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					attrs)),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[child])));
	});
var $author$project$Traveller$ClearAllErrors = {$: 'ClearAllErrors'};
var $elm$html$Html$Attributes$attribute = $elm$virtual_dom$VirtualDom$attribute;
var $mdgriffith$elm_ui$Internal$Model$Button = {$: 'Button'};
var $mdgriffith$elm_ui$Internal$Model$Describe = function (a) {
	return {$: 'Describe', a: a};
};
var $elm$html$Html$Attributes$boolProperty = F2(
	function (key, bool) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$bool(bool));
	});
var $elm$html$Html$Attributes$disabled = $elm$html$Html$Attributes$boolProperty('disabled');
var $mdgriffith$elm_ui$Element$Input$enter = 'Enter';
var $mdgriffith$elm_ui$Internal$Model$NoAttribute = {$: 'NoAttribute'};
var $mdgriffith$elm_ui$Element$Input$hasFocusStyle = function (attr) {
	if (((attr.$ === 'StyleClass') && (attr.b.$ === 'PseudoSelector')) && (attr.b.a.$ === 'Focus')) {
		var _v1 = attr.b;
		var _v2 = _v1.a;
		return true;
	} else {
		return false;
	}
};
var $mdgriffith$elm_ui$Element$Input$focusDefault = function (attrs) {
	return A2($elm$core$List$any, $mdgriffith$elm_ui$Element$Input$hasFocusStyle, attrs) ? $mdgriffith$elm_ui$Internal$Model$NoAttribute : $mdgriffith$elm_ui$Internal$Model$htmlClass('focusable');
};
var $mdgriffith$elm_ui$Element$Events$onClick = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Attr, $elm$html$Html$Events$onClick);
var $elm$virtual_dom$VirtualDom$MayPreventDefault = function (a) {
	return {$: 'MayPreventDefault', a: a};
};
var $elm$html$Html$Events$preventDefaultOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayPreventDefault(decoder));
	});
var $mdgriffith$elm_ui$Element$Input$onKeyLookup = function (lookup) {
	var decode = function (code) {
		var _v0 = lookup(code);
		if (_v0.$ === 'Nothing') {
			return $elm$json$Json$Decode$fail('No key matched');
		} else {
			var msg = _v0.a;
			return $elm$json$Json$Decode$succeed(msg);
		}
	};
	var isKey = A2(
		$elm$json$Json$Decode$andThen,
		decode,
		A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string));
	return $mdgriffith$elm_ui$Internal$Model$Attr(
		A2(
			$elm$html$Html$Events$preventDefaultOn,
			'keydown',
			A2(
				$elm$json$Json$Decode$map,
				function (fired) {
					return _Utils_Tuple2(fired, true);
				},
				isKey)));
};
var $mdgriffith$elm_ui$Internal$Model$Class = F2(
	function (a, b) {
		return {$: 'Class', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$cursor = $mdgriffith$elm_ui$Internal$Flag$flag(21);
var $mdgriffith$elm_ui$Element$pointer = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$cursor, $mdgriffith$elm_ui$Internal$Style$classes.cursorPointer);
var $mdgriffith$elm_ui$Element$Input$space = ' ';
var $elm$html$Html$Attributes$tabindex = function (n) {
	return A2(
		_VirtualDom_attribute,
		'tabIndex',
		$elm$core$String$fromInt(n));
};
var $mdgriffith$elm_ui$Element$Input$button = F2(
	function (attrs, _v0) {
		var onPress = _v0.onPress;
		var label = _v0.label;
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentCenterX + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.seButton + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.noTextSelection)))))),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$pointer,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$Input$focusDefault(attrs),
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Model$Describe($mdgriffith$elm_ui$Internal$Model$Button),
									A2(
										$elm$core$List$cons,
										$mdgriffith$elm_ui$Internal$Model$Attr(
											$elm$html$Html$Attributes$tabindex(0)),
										function () {
											if (onPress.$ === 'Nothing') {
												return A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Internal$Model$Attr(
														$elm$html$Html$Attributes$disabled(true)),
													attrs);
											} else {
												var msg = onPress.a;
												return A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Element$Events$onClick(msg),
													A2(
														$elm$core$List$cons,
														$mdgriffith$elm_ui$Element$Input$onKeyLookup(
															function (code) {
																return _Utils_eq(code, $mdgriffith$elm_ui$Element$Input$enter) ? $elm$core$Maybe$Just(msg) : (_Utils_eq(code, $mdgriffith$elm_ui$Element$Input$space) ? $elm$core$Maybe$Just(msg) : $elm$core$Maybe$Nothing);
															}),
														attrs));
											}
										}()))))))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[label])));
	});
var $elm$html$Html$Attributes$classList = function (classes) {
	return $elm$html$Html$Attributes$class(
		A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$map,
				$elm$core$Tuple$first,
				A2($elm$core$List$filter, $elm$core$Tuple$second, classes))));
};
var $mdgriffith$elm_ui$Element$rgba = $mdgriffith$elm_ui$Internal$Model$Rgba;
var $author$project$Traveller$UI$colorToElementColor = function (color) {
	return function (_v0) {
		var red = _v0.red;
		var green = _v0.green;
		var blue = _v0.blue;
		var alpha = _v0.alpha;
		return A4($mdgriffith$elm_ui$Element$rgba, red, green, blue, alpha);
	}(
		$avh4$elm_color$Color$toRgba(color));
};
var $avh4$elm_color$Color$green = A4($avh4$elm_color$Color$RgbaSpace, 115 / 255, 210 / 255, 22 / 255, 1.0);
var $avh4$elm_color$Color$grey = A4($avh4$elm_color$Color$RgbaSpace, 211 / 255, 215 / 255, 207 / 255, 1.0);
var $mdgriffith$elm_ui$Element$Font$italic = $mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.italic);
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$Attributes$rel = _VirtualDom_attribute('rel');
var $mdgriffith$elm_ui$Element$link = F2(
	function (attrs, _v0) {
		var url = _v0.url;
		var label = _v0.label;
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$NodeName('a'),
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$Attr(
					$elm$html$Html$Attributes$href(url)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Internal$Model$Attr(
						$elm$html$Html$Attributes$rel('noopener noreferrer')),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentCenterX + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.link)))),
								attrs))))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[label])));
	});
var $mdgriffith$elm_ui$Internal$Model$Min = F2(
	function (a, b) {
		return {$: 'Min', a: a, b: b};
	});
var $mdgriffith$elm_ui$Element$minimum = F2(
	function (i, l) {
		return A2($mdgriffith$elm_ui$Internal$Model$Min, i, l);
	});
var $mdgriffith$elm_ui$Element$Font$family = function (families) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$fontFamily,
		A2(
			$mdgriffith$elm_ui$Internal$Model$FontFamily,
			A3($elm$core$List$foldl, $mdgriffith$elm_ui$Internal$Model$renderFontClassName, 'ff-', families),
			families));
};
var $mdgriffith$elm_ui$Internal$Model$Monospace = {$: 'Monospace'};
var $mdgriffith$elm_ui$Element$Font$monospace = $mdgriffith$elm_ui$Internal$Model$Monospace;
var $mdgriffith$elm_ui$Internal$Model$Text = function (a) {
	return {$: 'Text', a: a};
};
var $mdgriffith$elm_ui$Element$text = function (content) {
	return $mdgriffith$elm_ui$Internal$Model$Text(content);
};
var $author$project$Traveller$UI$monospaceText = function (someString) {
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$Font$family(
				_List_fromArray(
					[$mdgriffith$elm_ui$Element$Font$monospace]))
			]),
		$mdgriffith$elm_ui$Element$text(someString));
};
var $mdgriffith$elm_ui$Internal$Model$Hover = {$: 'Hover'};
var $mdgriffith$elm_ui$Internal$Model$PseudoSelector = F2(
	function (a, b) {
		return {$: 'PseudoSelector', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$hover = $mdgriffith$elm_ui$Internal$Flag$flag(33);
var $mdgriffith$elm_ui$Internal$Model$Nearby = F2(
	function (a, b) {
		return {$: 'Nearby', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$TransformComponent = F2(
	function (a, b) {
		return {$: 'TransformComponent', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$map = F2(
	function (fn, el) {
		switch (el.$) {
			case 'Styled':
				var styled = el.a;
				return $mdgriffith$elm_ui$Internal$Model$Styled(
					{
						html: F2(
							function (add, context) {
								return A2(
									$elm$virtual_dom$VirtualDom$map,
									fn,
									A2(styled.html, add, context));
							}),
						styles: styled.styles
					});
			case 'Unstyled':
				var html = el.a;
				return $mdgriffith$elm_ui$Internal$Model$Unstyled(
					A2(
						$elm$core$Basics$composeL,
						$elm$virtual_dom$VirtualDom$map(fn),
						html));
			case 'Text':
				var str = el.a;
				return $mdgriffith$elm_ui$Internal$Model$Text(str);
			default:
				return $mdgriffith$elm_ui$Internal$Model$Empty;
		}
	});
var $elm$virtual_dom$VirtualDom$mapAttribute = _VirtualDom_mapAttribute;
var $mdgriffith$elm_ui$Internal$Model$mapAttrFromStyle = F2(
	function (fn, attr) {
		switch (attr.$) {
			case 'NoAttribute':
				return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
			case 'Describe':
				var description = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$Describe(description);
			case 'AlignX':
				var x = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$AlignX(x);
			case 'AlignY':
				var y = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$AlignY(y);
			case 'Width':
				var x = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$Width(x);
			case 'Height':
				var x = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$Height(x);
			case 'Class':
				var x = attr.a;
				var y = attr.b;
				return A2($mdgriffith$elm_ui$Internal$Model$Class, x, y);
			case 'StyleClass':
				var flag = attr.a;
				var style = attr.b;
				return A2($mdgriffith$elm_ui$Internal$Model$StyleClass, flag, style);
			case 'Nearby':
				var location = attr.a;
				var elem = attr.b;
				return A2(
					$mdgriffith$elm_ui$Internal$Model$Nearby,
					location,
					A2($mdgriffith$elm_ui$Internal$Model$map, fn, elem));
			case 'Attr':
				var htmlAttr = attr.a;
				return $mdgriffith$elm_ui$Internal$Model$Attr(
					A2($elm$virtual_dom$VirtualDom$mapAttribute, fn, htmlAttr));
			default:
				var fl = attr.a;
				var trans = attr.b;
				return A2($mdgriffith$elm_ui$Internal$Model$TransformComponent, fl, trans);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$removeNever = function (style) {
	return A2($mdgriffith$elm_ui$Internal$Model$mapAttrFromStyle, $elm$core$Basics$never, style);
};
var $mdgriffith$elm_ui$Internal$Model$unwrapDecsHelper = F2(
	function (attr, _v0) {
		var styles = _v0.a;
		var trans = _v0.b;
		var _v1 = $mdgriffith$elm_ui$Internal$Model$removeNever(attr);
		switch (_v1.$) {
			case 'StyleClass':
				var style = _v1.b;
				return _Utils_Tuple2(
					A2($elm$core$List$cons, style, styles),
					trans);
			case 'TransformComponent':
				var flag = _v1.a;
				var component = _v1.b;
				return _Utils_Tuple2(
					styles,
					A2($mdgriffith$elm_ui$Internal$Model$composeTransformation, trans, component));
			default:
				return _Utils_Tuple2(styles, trans);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$unwrapDecorations = function (attrs) {
	var _v0 = A3(
		$elm$core$List$foldl,
		$mdgriffith$elm_ui$Internal$Model$unwrapDecsHelper,
		_Utils_Tuple2(_List_Nil, $mdgriffith$elm_ui$Internal$Model$Untransformed),
		attrs);
	var styles = _v0.a;
	var transform = _v0.b;
	return A2(
		$elm$core$List$cons,
		$mdgriffith$elm_ui$Internal$Model$Transform(transform),
		styles);
};
var $mdgriffith$elm_ui$Element$mouseOver = function (decs) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$hover,
		A2(
			$mdgriffith$elm_ui$Internal$Model$PseudoSelector,
			$mdgriffith$elm_ui$Internal$Model$Hover,
			$mdgriffith$elm_ui$Internal$Model$unwrapDecorations(decs)));
};
var $mdgriffith$elm_ui$Internal$Model$PaddingStyle = F5(
	function (a, b, c, d, e) {
		return {$: 'PaddingStyle', a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Internal$Flag$padding = $mdgriffith$elm_ui$Internal$Flag$flag(2);
var $mdgriffith$elm_ui$Element$padding = function (x) {
	var f = x;
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$padding,
		A5(
			$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
			'p-' + $elm$core$String$fromInt(x),
			f,
			f,
			f,
			f));
};
var $mdgriffith$elm_ui$Internal$Model$Px = function (a) {
	return {$: 'Px', a: a};
};
var $mdgriffith$elm_ui$Element$px = $mdgriffith$elm_ui$Internal$Model$Px;
var $mdgriffith$elm_ui$Element$rgb = F3(
	function (r, g, b) {
		return A4($mdgriffith$elm_ui$Internal$Model$Rgba, r, g, b, 1);
	});
var $mdgriffith$elm_ui$Internal$Flag$borderRound = $mdgriffith$elm_ui$Internal$Flag$flag(17);
var $mdgriffith$elm_ui$Element$Border$rounded = function (radius) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderRound,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Single,
			'br-' + $elm$core$String$fromInt(radius),
			'border-radius',
			$elm$core$String$fromInt(radius) + 'px'));
};
var $mdgriffith$elm_ui$Internal$Model$AsRow = {$: 'AsRow'};
var $mdgriffith$elm_ui$Internal$Model$asRow = $mdgriffith$elm_ui$Internal$Model$AsRow;
var $mdgriffith$elm_ui$Element$row = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asRow,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentLeft + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.contentCenterY)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $mdgriffith$elm_ui$Internal$Flag$overflow = $mdgriffith$elm_ui$Internal$Flag$flag(20);
var $mdgriffith$elm_ui$Element$scrollbars = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$overflow, $mdgriffith$elm_ui$Internal$Style$classes.scrollbars);
var $mdgriffith$elm_ui$Element$Font$size = function (i) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$fontSize,
		$mdgriffith$elm_ui$Internal$Model$FontSize(i));
};
var $mdgriffith$elm_ui$Internal$Model$SpacingStyle = F3(
	function (a, b, c) {
		return {$: 'SpacingStyle', a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Flag$spacing = $mdgriffith$elm_ui$Internal$Flag$flag(3);
var $mdgriffith$elm_ui$Internal$Model$spacingName = F2(
	function (x, y) {
		return 'spacing-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y)));
	});
var $mdgriffith$elm_ui$Element$spacing = function (x) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$spacing,
		A3(
			$mdgriffith$elm_ui$Internal$Model$SpacingStyle,
			A2($mdgriffith$elm_ui$Internal$Model$spacingName, x, x),
			x,
			x));
};
var $mdgriffith$elm_ui$Internal$Model$AsTextColumn = {$: 'AsTextColumn'};
var $mdgriffith$elm_ui$Internal$Model$asTextColumn = $mdgriffith$elm_ui$Internal$Model$AsTextColumn;
var $mdgriffith$elm_ui$Internal$Model$Max = F2(
	function (a, b) {
		return {$: 'Max', a: a, b: b};
	});
var $mdgriffith$elm_ui$Element$maximum = F2(
	function (i, l) {
		return A2($mdgriffith$elm_ui$Internal$Model$Max, i, l);
	});
var $mdgriffith$elm_ui$Element$textColumn = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asTextColumn,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width(
					A2(
						$mdgriffith$elm_ui$Element$maximum,
						750,
						A2($mdgriffith$elm_ui$Element$minimum, 500, $mdgriffith$elm_ui$Element$fill))),
				attrs),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $mdgriffith$elm_ui$Element$Font$underline = $mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.underline);
var $mdgriffith$elm_ui$Internal$Model$BorderWidth = F5(
	function (a, b, c, d, e) {
		return {$: 'BorderWidth', a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Element$Border$width = function (v) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderWidth,
		A5(
			$mdgriffith$elm_ui$Internal$Model$BorderWidth,
			'b-' + $elm$core$String$fromInt(v),
			v,
			v,
			v,
			v));
};
var $author$project$Traveller$errorDialog = function (httpErrors) {
	var renderError = function (_v2) {
		var httpError = _v2.a;
		var url = _v2.b;
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$link,
					_List_Nil,
					{
						label: A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$mouseOver(
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$Font$color(
											$author$project$Traveller$UI$colorToElementColor($avh4$elm_color$Color$green))
										])),
									$mdgriffith$elm_ui$Element$Font$italic,
									$mdgriffith$elm_ui$Element$Font$color(
									$author$project$Traveller$UI$colorToElementColor($avh4$elm_color$Color$grey))
								]),
							$author$project$Traveller$UI$monospaceText(url)),
						url: url
					}),
					function () {
					switch (httpError.$) {
						case 'BadBody':
							var error = httpError.a;
							return A2(
								$mdgriffith$elm_ui$Element$textColumn,
								_List_Nil,
								_List_fromArray(
									[
										$author$project$Traveller$UI$monospaceText('JSON Decode Error:'),
										$author$project$Traveller$UI$monospaceText(error)
									]));
						case 'BadUrl':
							var url_ = httpError.a;
							return $mdgriffith$elm_ui$Element$text('Invalid URL: ' + url_);
						case 'NetworkError':
							return $mdgriffith$elm_ui$Element$text('Network Error');
						case 'BadStatus':
							var statusCode = httpError.a;
							return $mdgriffith$elm_ui$Element$text(
								'BadStatus: ' + $elm$core$String$fromInt(statusCode));
						default:
							return $mdgriffith$elm_ui$Element$text('Request timedout');
					}
				}()
				]));
	};
	var pluralize = F3(
		function (n, singular, plural) {
			return (n === 1) ? singular : plural;
		});
	var openAttr = A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$List$isEmpty)(httpErrors) ? A2($elm$html$Html$Attributes$attribute, 'open', 'open') : $elm$html$Html$Attributes$classList(_List_Nil);
	var errorButton = function (_v0) {
		var onPress = _v0.onPress;
		var label = _v0.label;
		return A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(100)),
					$mdgriffith$elm_ui$Element$Border$width(2),
					$mdgriffith$elm_ui$Element$Border$rounded(10),
					$mdgriffith$elm_ui$Element$padding(10),
					$mdgriffith$elm_ui$Element$mouseOver(
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$Background$color(
							A3($mdgriffith$elm_ui$Element$rgb, 0.5, 0.5, 0.5))
						]))
				]),
			{
				label: A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[$mdgriffith$elm_ui$Element$centerX]),
					$mdgriffith$elm_ui$Element$text(label)),
				onPress: onPress
			});
	};
	return A3(
		$elm$html$Html$node,
		'dialog',
		_List_fromArray(
			[openAttr]),
		_List_fromArray(
			[
				A3(
				$mdgriffith$elm_ui$Element$layoutWith,
				{
					options: _List_fromArray(
						[$mdgriffith$elm_ui$Element$noStaticStyleSheet])
				},
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$centerX,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
					]),
				A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$height(
							A2($mdgriffith$elm_ui$Element$minimum, 500, $mdgriffith$elm_ui$Element$fill)),
							$mdgriffith$elm_ui$Element$width(
							A2($mdgriffith$elm_ui$Element$minimum, 500, $mdgriffith$elm_ui$Element$fill)),
							$mdgriffith$elm_ui$Element$Font$color(
							A3($mdgriffith$elm_ui$Element$rgb, 1, 1, 1)),
							$mdgriffith$elm_ui$Element$scrollbars,
							$mdgriffith$elm_ui$Element$spacing(10)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$centerX,
									$mdgriffith$elm_ui$Element$Font$size(24),
									$mdgriffith$elm_ui$Element$Font$underline,
									$mdgriffith$elm_ui$Element$padding(10)
								]),
							function () {
								var errorCount = $elm$core$List$length(httpErrors);
								return $mdgriffith$elm_ui$Element$text(
									A3(
										pluralize,
										errorCount,
										'One Error!',
										'Many errors! (' + ($elm$core$String$fromInt(errorCount) + ' of \'em)')));
							}()),
							A2(
							$mdgriffith$elm_ui$Element$column,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$spacing(10),
									$mdgriffith$elm_ui$Element$height(
									A2($mdgriffith$elm_ui$Element$minimum, 100, $mdgriffith$elm_ui$Element$fill)),
									$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
									$mdgriffith$elm_ui$Element$scrollbars,
									$mdgriffith$elm_ui$Element$Font$size(16)
								]),
							A2($elm$core$List$map, renderError, httpErrors)),
							A2(
							$mdgriffith$elm_ui$Element$row,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$centerX,
									$mdgriffith$elm_ui$Element$spacing(10)
								]),
							_List_fromArray(
								[
									errorButton(
									{
										label: 'Close',
										onPress: $elm$core$Maybe$Just($author$project$Traveller$ClearAllErrors)
									})
								]))
						])))
			]));
};
var $author$project$Traveller$UI$textColor = A3($avh4$elm_color$Color$rgb, 0.5, 1.0, 0.5);
var $author$project$Traveller$UI$fontTextColor = $author$project$Traveller$UI$colorToElementColor($author$project$Traveller$UI$textColor);
var $mdgriffith$elm_ui$Internal$Model$unstyled = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Unstyled, $elm$core$Basics$always);
var $mdgriffith$elm_ui$Element$html = $mdgriffith$elm_ui$Internal$Model$unstyled;
var $mdgriffith$elm_ui$Internal$Model$InFront = {$: 'InFront'};
var $mdgriffith$elm_ui$Element$createNearby = F2(
	function (loc, element) {
		if (element.$ === 'Empty') {
			return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
		} else {
			return A2($mdgriffith$elm_ui$Internal$Model$Nearby, loc, element);
		}
	});
var $mdgriffith$elm_ui$Element$inFront = function (element) {
	return A2($mdgriffith$elm_ui$Element$createNearby, $mdgriffith$elm_ui$Internal$Model$InFront, element);
};
var $mdgriffith$elm_ui$Element$Lazy$embed = function (x) {
	switch (x.$) {
		case 'Unstyled':
			var html = x.a;
			return html;
		case 'Styled':
			var styled = x.a;
			return styled.html(
				A2(
					$mdgriffith$elm_ui$Internal$Model$OnlyDynamic,
					{
						focus: {backgroundColor: $elm$core$Maybe$Nothing, borderColor: $elm$core$Maybe$Nothing, shadow: $elm$core$Maybe$Nothing},
						hover: $mdgriffith$elm_ui$Internal$Model$AllowHover,
						mode: $mdgriffith$elm_ui$Internal$Model$Layout
					},
					styled.styles));
		case 'Text':
			var text = x.a;
			return $elm$core$Basics$always(
				$elm$virtual_dom$VirtualDom$text(text));
		default:
			return $elm$core$Basics$always(
				$elm$virtual_dom$VirtualDom$text(''));
	}
};
var $mdgriffith$elm_ui$Element$Lazy$apply2 = F3(
	function (fn, a, b) {
		return $mdgriffith$elm_ui$Element$Lazy$embed(
			A2(fn, a, b));
	});
var $elm$virtual_dom$VirtualDom$lazy4 = _VirtualDom_lazy4;
var $mdgriffith$elm_ui$Element$Lazy$lazy2 = F3(
	function (fn, a, b) {
		return $mdgriffith$elm_ui$Internal$Model$Unstyled(
			A4($elm$virtual_dom$VirtualDom$lazy4, $mdgriffith$elm_ui$Element$Lazy$apply2, fn, a, b));
	});
var $mdgriffith$elm_ui$Element$paddingXY = F2(
	function (x, y) {
		if (_Utils_eq(x, y)) {
			var f = x;
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$padding,
				A5(
					$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
					'p-' + $elm$core$String$fromInt(x),
					f,
					f,
					f,
					f));
		} else {
			var yFloat = y;
			var xFloat = x;
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$padding,
				A5(
					$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
					'p-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y))),
					yFloat,
					xFloat,
					yFloat,
					xFloat));
		}
	});
var $elm$time$Time$posixToMillis = function (_v0) {
	var millis = _v0.a;
	return millis;
};
var $mdgriffith$elm_ui$Element$rgb255 = F3(
	function (red, green, blue) {
		return A4($mdgriffith$elm_ui$Internal$Model$Rgba, red / 255, green / 255, blue / 255, 1);
	});
var $author$project$Traveller$JourneyMsg = function (a) {
	return {$: 'JourneyMsg', a: a};
};
var $author$project$Traveller$MouseDown = function (a) {
	return {$: 'MouseDown', a: a};
};
var $author$project$Traveller$MouseLeave = {$: 'MouseLeave'};
var $author$project$Traveller$MouseMove = function (a) {
	return {$: 'MouseMove', a: a};
};
var $author$project$Traveller$MouseUp = function (a) {
	return {$: 'MouseUp', a: a};
};
var $mdgriffith$elm_ui$Element$clip = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$overflow, $mdgriffith$elm_ui$Internal$Style$classes.clip);
var $elm$html$Html$Attributes$alt = $elm$html$Html$Attributes$stringProperty('alt');
var $elm$html$Html$Attributes$src = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'src',
		_VirtualDom_noJavaScriptOrHtmlUri(url));
};
var $mdgriffith$elm_ui$Element$image = F2(
	function (attrs, _v0) {
		var src = _v0.src;
		var description = _v0.description;
		var imageAttributes = A2(
			$elm$core$List$filter,
			function (a) {
				switch (a.$) {
					case 'Width':
						return true;
					case 'Height':
						return true;
					default:
						return false;
				}
			},
			attrs);
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.imageContainer),
				attrs),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[
						A4(
						$mdgriffith$elm_ui$Internal$Model$element,
						$mdgriffith$elm_ui$Internal$Model$asEl,
						$mdgriffith$elm_ui$Internal$Model$NodeName('img'),
						_Utils_ap(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Internal$Model$Attr(
									$elm$html$Html$Attributes$src(src)),
									$mdgriffith$elm_ui$Internal$Model$Attr(
									$elm$html$Html$Attributes$alt(description))
								]),
							imageAttributes),
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(_List_Nil))
					])));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$Event = F6(
	function (keys, button, clientPos, offsetPos, pagePos, screenPos) {
		return {button: button, clientPos: clientPos, keys: keys, offsetPos: offsetPos, pagePos: pagePos, screenPos: screenPos};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$BackButton = {$: 'BackButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ErrorButton = {$: 'ErrorButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ForwardButton = {$: 'ForwardButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MainButton = {$: 'MainButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MiddleButton = {$: 'MiddleButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$SecondButton = {$: 'SecondButton'};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonFromId = function (id) {
	switch (id) {
		case 0:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MainButton;
		case 1:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MiddleButton;
		case 2:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$SecondButton;
		case 3:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$BackButton;
		case 4:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ForwardButton;
		default:
			return $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ErrorButton;
	}
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonDecoder = A2(
	$elm$json$Json$Decode$map,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonFromId,
	A2($elm$json$Json$Decode$field, 'button', $elm$json$Json$Decode$int));
var $mpizenberg$elm_pointer_events$Internal$Decode$clientPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$Keys = F4(
	function (alt, ctrl, meta, shift) {
		return {alt: alt, ctrl: ctrl, meta: meta, shift: shift};
	});
var $elm$json$Json$Decode$map4 = _Json_map4;
var $mpizenberg$elm_pointer_events$Internal$Decode$keys = A5(
	$elm$json$Json$Decode$map4,
	$mpizenberg$elm_pointer_events$Internal$Decode$Keys,
	A2($elm$json$Json$Decode$field, 'altKey', $elm$json$Json$Decode$bool),
	A2($elm$json$Json$Decode$field, 'ctrlKey', $elm$json$Json$Decode$bool),
	A2($elm$json$Json$Decode$field, 'metaKey', $elm$json$Json$Decode$bool),
	A2($elm$json$Json$Decode$field, 'shiftKey', $elm$json$Json$Decode$bool));
var $elm$json$Json$Decode$map6 = _Json_map6;
var $mpizenberg$elm_pointer_events$Internal$Decode$offsetPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'offsetX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'offsetY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$pagePos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'pageX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'pageY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$screenPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'screenX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'screenY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder = A7($elm$json$Json$Decode$map6, $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$Event, $mpizenberg$elm_pointer_events$Internal$Decode$keys, $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonDecoder, $mpizenberg$elm_pointer_events$Internal$Decode$clientPos, $mpizenberg$elm_pointer_events$Internal$Decode$offsetPos, $mpizenberg$elm_pointer_events$Internal$Decode$pagePos, $mpizenberg$elm_pointer_events$Internal$Decode$screenPos);
var $author$project$Traveller$mouseDownDecoder = function (onDownMsg) {
	var jsMouseEventDecoder = A2(
		$elm$json$Json$Decode$andThen,
		function (evt) {
			var _v0 = evt.button;
			if (_v0.$ === 'MainButton') {
				return $elm$json$Json$Decode$succeed(evt);
			} else {
				return $elm$json$Json$Decode$fail('Won\'t drag on non-main/left button');
			}
		},
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder);
	return A2(
		$elm$json$Json$Decode$map,
		function (evt) {
			return onDownMsg(evt.offsetPos);
		},
		jsMouseEventDecoder);
};
var $author$project$Traveller$mouseMoveDecoder = function (onMoveMsg) {
	return A2(
		$elm$json$Json$Decode$map,
		A2(
			$elm$core$Basics$composeR,
			function ($) {
				return $.offsetPos;
			},
			onMoveMsg),
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder);
};
var $author$project$Traveller$mouseUpDecoder = function (onDownMsg) {
	var jsMouseEventDecoder = A2(
		$elm$json$Json$Decode$andThen,
		function (evt) {
			var _v0 = evt.button;
			if (_v0.$ === 'MainButton') {
				return $elm$json$Json$Decode$succeed(evt);
			} else {
				return $elm$json$Json$Decode$fail('Won\'t drag on non-main/left button');
			}
		},
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder);
	return A2(
		$elm$json$Json$Decode$map,
		function (evt) {
			return onDownMsg(evt.offsetPos);
		},
		jsMouseEventDecoder);
};
var $mdgriffith$elm_ui$Internal$Model$MoveY = function (a) {
	return {$: 'MoveY', a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$moveY = $mdgriffith$elm_ui$Internal$Flag$flag(26);
var $mdgriffith$elm_ui$Element$moveDown = function (y) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveY,
		$mdgriffith$elm_ui$Internal$Model$MoveY(y));
};
var $mdgriffith$elm_ui$Internal$Model$MoveX = function (a) {
	return {$: 'MoveX', a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$moveX = $mdgriffith$elm_ui$Internal$Flag$flag(25);
var $mdgriffith$elm_ui$Element$moveRight = function (x) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveX,
		$mdgriffith$elm_ui$Internal$Model$MoveX(x));
};
var $author$project$Traveller$noopAttribute = $mdgriffith$elm_ui$Element$htmlAttribute(
	A2($elm$html$Html$Attributes$style, '', ''));
var $elm$html$Html$Events$onMouseLeave = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseleave',
		$elm$json$Json$Decode$succeed(msg));
};
var $mdgriffith$elm_ui$Element$Events$onMouseLeave = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Attr, $elm$html$Html$Events$onMouseLeave);
var $author$project$Traveller$pointerEventsNone = $mdgriffith$elm_ui$Element$htmlAttribute(
	A2($elm$html$Html$Attributes$style, 'pointer-events', 'none'));
var $author$project$Traveller$userSelectNone = $mdgriffith$elm_ui$Element$htmlAttribute(
	A2($elm$html$Html$Attributes$style, 'user-select', 'none'));
var $author$project$Traveller$viewFullJourney = F2(
	function (model, viewport) {
		var _v0 = model.zoomOffset;
		var offsetLeft = _v0.a;
		var offsetTop = _v0.b;
		var _v1 = function () {
			var scaledWidth = (viewport.viewport.width - $author$project$Traveller$Sidebar$sidebarWidth) - 50;
			return _Utils_Tuple2(scaledWidth, scaledWidth * ($author$project$Traveller$fullJourneyImageHeight / $author$project$Traveller$fullJourneyImageWidth));
		}();
		var maxWidth = _v1.a;
		var maxHeight = _v1.b;
		var _v2 = _Utils_Tuple2(maxWidth * model.zoomScale, maxHeight * model.zoomScale);
		var imageSizeWidth = _v2.a;
		var imageSizeHeight = _v2.b;
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$alignTop,
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(
						$elm$core$Basics$floor(maxWidth))),
					$mdgriffith$elm_ui$Element$height(
					$mdgriffith$elm_ui$Element$px(
						$elm$core$Basics$floor(maxHeight))),
					$mdgriffith$elm_ui$Element$clip,
					$mdgriffith$elm_ui$Element$htmlAttribute(
					A2(
						$elm$html$Html$Events$on,
						'mousemove',
						$author$project$Traveller$mouseMoveDecoder(
							A2($elm$core$Basics$composeL, $author$project$Traveller$JourneyMsg, $author$project$Traveller$MouseMove)))),
					$mdgriffith$elm_ui$Element$htmlAttribute(
					A2(
						$elm$html$Html$Events$on,
						'mousedown',
						$author$project$Traveller$mouseDownDecoder(
							A2($elm$core$Basics$composeL, $author$project$Traveller$JourneyMsg, $author$project$Traveller$MouseDown)))),
					$mdgriffith$elm_ui$Element$htmlAttribute(
					A2(
						$elm$html$Html$Events$on,
						'mouseup',
						$author$project$Traveller$mouseUpDecoder(
							A2($elm$core$Basics$composeL, $author$project$Traveller$JourneyMsg, $author$project$Traveller$MouseUp)))),
					$mdgriffith$elm_ui$Element$Events$onMouseLeave(
					$author$project$Traveller$JourneyMsg($author$project$Traveller$MouseLeave)),
					$mdgriffith$elm_ui$Element$Background$color(
					A3($mdgriffith$elm_ui$Element$rgb, 1.0, 0.498, 0.0))
				]),
			A2(
				$mdgriffith$elm_ui$Element$image,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$width(
						$mdgriffith$elm_ui$Element$px(
							$elm$core$Basics$floor(imageSizeWidth))),
						$mdgriffith$elm_ui$Element$height(
						$mdgriffith$elm_ui$Element$px(
							$elm$core$Basics$floor(imageSizeHeight))),
						$mdgriffith$elm_ui$Element$moveRight(offsetLeft),
						$mdgriffith$elm_ui$Element$moveDown(offsetTop),
						$author$project$Traveller$pointerEventsNone,
						$author$project$Traveller$userSelectNone,
						function () {
						var _v3 = model.hoverPoint;
						if (_v3.$ === 'Just') {
							var _v4 = _v3.a;
							var hovX = _v4.a;
							var hovY = _v4.b;
							return $mdgriffith$elm_ui$Element$inFront(
								function () {
									var _v5 = _Utils_Tuple2(17, 14);
									var sectorsAcross = _v5.a;
									var sectorsTall = _v5.b;
									var _v6 = _Utils_Tuple2((hovX - offsetLeft) / (imageSizeWidth / sectorsAcross), (hovY - offsetTop) / (imageSizeHeight / sectorsTall));
									var sectorX = _v6.a;
									var sectorY = _v6.b;
									var _v7 = _Utils_Tuple2(
										$elm$core$Basics$floor(sectorX) * (imageSizeWidth / sectorsAcross),
										$elm$core$Basics$floor(sectorY) * (imageSizeHeight / sectorsTall));
									var xoff = _v7.a;
									var yoff = _v7.b;
									var _v8 = function () {
										var _v9 = _Utils_Tuple2(5, 1);
										var oursX = _v9.a;
										var oursY = _v9.b;
										var _v10 = _Utils_Tuple2(-21, -2);
										var officialX = _v10.a;
										var officialY = _v10.b;
										return _Utils_Tuple2(officialX - oursX, officialY + oursY);
									}();
									var correctedX = _v8.a;
									var correctedY = _v8.b;
									return A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$moveRight(xoff),
												$mdgriffith$elm_ui$Element$moveDown(yoff),
												$author$project$Traveller$userSelectNone,
												$author$project$Traveller$pointerEventsNone,
												$mdgriffith$elm_ui$Element$Font$size(14)
											]),
										$mdgriffith$elm_ui$Element$text(
											'Sector: ' + ($elm$core$String$fromInt(
												correctedX + $elm$core$Basics$floor(sectorX)) + (', ' + $elm$core$String$fromInt(
												correctedY - $elm$core$Basics$floor(sectorY))))));
								}());
						} else {
							return $author$project$Traveller$noopAttribute;
						}
					}()
					]),
				{description: 'Full Journey Map', src: '/images/uncharted-space.png'}));
	});
var $author$project$Traveller$HexGeometry$hexColOffset = function (row) {
	return (!(row % 2)) ? 1.0 : 0.0;
};
var $author$project$Traveller$HexGeometry$calcVisualOrigin = F2(
	function (hexSize, _v0) {
		var row = _v0.row;
		var col = _v0.col;
		var y = (-1) * ((hexSize + (((row * 2) * hexSize) * $elm$core$Basics$sin($author$project$Traveller$HexGeometry$hexSizeFactor))) + ((hexSize * $author$project$Traveller$HexGeometry$hexColOffset(col)) * $elm$core$Basics$sin($author$project$Traveller$HexGeometry$hexSizeFactor)));
		var x = hexSize + (col * (hexSize + (hexSize * $elm$core$Basics$cos($author$project$Traveller$HexGeometry$hexSizeFactor))));
		return _Utils_Tuple2(
			$elm$core$Basics$floor(x),
			$elm$core$Basics$floor(y));
	});
var $author$project$Traveller$consoleTitleHeight = 46;
var $author$project$Traveller$MapMouseLeave = {$: 'MapMouseLeave'};
var $author$project$Traveller$HexAddress$betweenWithMax = F3(
	function (upperLeftHex, lowerRightHex, _v0) {
		var maxAcross = _v0.maxAcross;
		var maxTall = _v0.maxTall;
		var tall = A2($elm$core$Basics$min, upperLeftHex.y - lowerRightHex.y, maxTall);
		var across = A2($elm$core$Basics$min, lowerRightHex.x - upperLeftHex.x, maxAcross);
		return A2(
			$elm$core$List$concatMap,
			function (x) {
				return A2(
					$elm$core$List$map,
					function (y) {
						return {x: x, y: y};
					},
					A2($elm$core$List$range, upperLeftHex.y - tall, upperLeftHex.y));
			},
			A2($elm$core$List$range, upperLeftHex.x, upperLeftHex.x + across));
	});
var $author$project$Traveller$currentAddressHexBg = '#fe5a1d';
var $elm$svg$Svg$Attributes$height = _VirtualDom_attribute('height');
var $author$project$Traveller$allegianceColours = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('C', '#F0FFFF'),
			_Utils_Tuple2('GR', '#FFDAB9'),
			_Utils_Tuple2('AL', '#D2691E')
		]));
var $author$project$Traveller$defaultHexBg = '#f5f5f5';
var $author$project$Traveller$extinctSophontHexBg = '#EEE8AA';
var $author$project$Traveller$nativeSophontHexBg = '#B0E0E6';
var $author$project$Traveller$hexBackgroundColour = F3(
	function (referee, hexKey, solarSystemDict) {
		if (referee) {
			var _v0 = A2($elm$core$Dict$get, hexKey, solarSystemDict);
			if (_v0.$ === 'Just') {
				var rss = _v0.a;
				if (rss.$ === 'LoadedSolarSystem') {
					var system = rss.a;
					var _v2 = system.allegiance;
					if (_v2.$ === 'Just') {
						var allegiance = _v2.a;
						var _v3 = A2($elm$core$Dict$get, allegiance, $author$project$Traveller$allegianceColours);
						if (_v3.$ === 'Just') {
							var color = _v3.a;
							return color;
						} else {
							return $author$project$Traveller$nativeSophontHexBg;
						}
					} else {
						return system.nativeSophont ? $author$project$Traveller$nativeSophontHexBg : (system.extinctSophont ? $author$project$Traveller$extinctSophontHexBg : $author$project$Traveller$defaultHexBg);
					}
				} else {
					return $author$project$Traveller$defaultHexBg;
				}
			} else {
				return $author$project$Traveller$defaultHexBg;
			}
		} else {
			return $author$project$Traveller$defaultHexBg;
		}
	});
var $author$project$Traveller$HexGeometry$hexagonPoints = F2(
	function (_v0, size) {
		var xOrigin = _v0.a;
		var yOrigin = _v0.b;
		return A2(
			$elm$core$List$map,
			function (_v1) {
				var x = _v1.a;
				var y = _v1.b;
				return $elm$core$String$fromFloat(xOrigin + x) + (',' + $elm$core$String$fromFloat(yOrigin + y));
			},
			$author$project$Traveller$HexGeometry$rawHexagonPoints(size));
	});
var $elm$svg$Svg$Attributes$id = _VirtualDom_attribute('id');
var $author$project$Traveller$isOnRoute = F2(
	function (route, address) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a.address, address);
			},
			route);
	});
var $elm$virtual_dom$VirtualDom$lazy2 = _VirtualDom_lazy2;
var $elm$svg$Svg$Lazy$lazy2 = $elm$virtual_dom$VirtualDom$lazy2;
var $elm$virtual_dom$VirtualDom$lazy3 = _VirtualDom_lazy3;
var $elm$html$Html$Lazy$lazy3 = $elm$virtual_dom$VirtualDom$lazy3;
var $elm$core$Tuple$mapBoth = F3(
	function (funcA, funcB, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			funcA(x),
			funcB(y));
	});
var $elm$virtual_dom$VirtualDom$keyedNodeNS = F2(
	function (namespace, tag) {
		return A2(
			_VirtualDom_keyedNodeNS,
			namespace,
			_VirtualDom_noScript(tag));
	});
var $elm$svg$Svg$Keyed$node = $elm$virtual_dom$VirtualDom$keyedNodeNS('http://www.w3.org/2000/svg');
var $elm$svg$Svg$Events$onMouseOut = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseout',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$svg$Svg$Attributes$dominantBaseline = _VirtualDom_attribute('dominant-baseline');
var $elm$svg$Svg$Attributes$fill = _VirtualDom_attribute('fill');
var $elm$svg$Svg$Attributes$fontFamily = _VirtualDom_attribute('font-family');
var $elm$svg$Svg$Attributes$fontWeight = _VirtualDom_attribute('font-weight');
var $elm$svg$Svg$Attributes$style = _VirtualDom_attribute('style');
var $elm$svg$Svg$text = $elm$virtual_dom$VirtualDom$text;
var $elm$svg$Svg$Attributes$textAnchor = _VirtualDom_attribute('text-anchor');
var $elm$svg$Svg$trustedNode = _VirtualDom_nodeNS('http://www.w3.org/2000/svg');
var $elm$svg$Svg$text_ = $elm$svg$Svg$trustedNode('text');
var $elm$svg$Svg$Attributes$x = _VirtualDom_attribute('x');
var $elm$svg$Svg$Attributes$y = _VirtualDom_attribute('y');
var $author$project$Traveller$regionLabel = F3(
	function (x, y, name) {
		return A2(
			$elm$svg$Svg$text_,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x(
					$elm$core$String$fromInt(x)),
					$elm$svg$Svg$Attributes$y(
					$elm$core$String$fromInt(y)),
					$elm$svg$Svg$Attributes$textAnchor('middle'),
					$elm$svg$Svg$Attributes$dominantBaseline('middle'),
					$elm$svg$Svg$Attributes$fontFamily('Tomorrow'),
					$elm$svg$Svg$Attributes$fontWeight('500'),
					$elm$svg$Svg$Attributes$fill('#0A0A0A'),
					$elm$svg$Svg$Attributes$style('pointer-events: none; user-select: none;')
				]),
			_List_fromArray(
				[
					$elm$svg$Svg$text(name)
				]));
	});
var $elm$svg$Svg$Attributes$pointerEvents = _VirtualDom_attribute('pointer-events');
var $elm$svg$Svg$Attributes$points = _VirtualDom_attribute('points');
var $elm$svg$Svg$polyline = $elm$svg$Svg$trustedNode('polyline');
var $elm$svg$Svg$Attributes$stroke = _VirtualDom_attribute('stroke');
var $elm$svg$Svg$Attributes$strokeWidth = _VirtualDom_attribute('stroke-width');
var $author$project$Traveller$renderPolyline = F2(
	function (points_, borderColour) {
		return A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points(points_),
					$elm$svg$Svg$Attributes$stroke(borderColour),
					$elm$svg$Svg$Attributes$fill('none'),
					$elm$svg$Svg$Attributes$strokeWidth('2'),
					$elm$svg$Svg$Attributes$pointerEvents('visiblePainted')
				]),
			_List_Nil);
	});
var $author$project$Traveller$renderSectorOutline = F2(
	function (hexSize, hex) {
		var topRight = $author$project$Traveller$HexAddress$toUniversalAddress(
			_Utils_update(
				hex,
				{x: 32, y: 0}));
		var topLeft = $author$project$Traveller$HexAddress$toUniversalAddress(
			_Utils_update(
				hex,
				{x: 0, y: 0}));
		var hWidth = $elm$core$Basics$floor(
			$author$project$Traveller$HexGeometry$hexWidth(hexSize));
		var hHeight = $elm$core$Basics$floor(
			$author$project$Traveller$HexGeometry$hexHeight(hexSize));
		var computePoints = function (hexAddr) {
			return function (_v1) {
				var x = _v1.a;
				var y = _v1.b;
				return $elm$core$String$fromInt(x) + (', ' + $elm$core$String$fromInt(y));
			}(
				function (_v0) {
					var x = _v0.a;
					var y = _v0.b;
					return _Utils_Tuple2(x - ((hWidth / 2) | 0), y - ((hHeight / 2) | 0));
				}(
					A2(
						$author$project$Traveller$HexGeometry$calcVisualOrigin,
						hexSize,
						{col: hexAddr.x, row: hexAddr.y})));
		};
		var botRight = $author$project$Traveller$HexAddress$toUniversalAddress(
			_Utils_update(
				hex,
				{x: 32, y: 40}));
		var botLeft = $author$project$Traveller$HexAddress$toUniversalAddress(
			_Utils_update(
				hex,
				{x: 0, y: 40}));
		var points_ = A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$map,
				computePoints,
				_List_fromArray(
					[topLeft, topRight, botRight, botLeft, topLeft])));
		return A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points(points_),
					$elm$svg$Svg$Attributes$id(
					'sectorOutline-' + ($elm$core$String$fromInt(hex.sectorX) + ('-' + $elm$core$String$fromInt(hex.sectorY)))),
					$elm$svg$Svg$Attributes$stroke('#0a0a0a40'),
					$elm$svg$Svg$Attributes$fill('none'),
					$elm$svg$Svg$Attributes$strokeWidth('3'),
					$elm$svg$Svg$Attributes$pointerEvents('visiblePainted')
				]),
			_List_Nil);
	});
var $author$project$Traveller$routeHexBg = '#FCD299';
var $author$project$Traveller$selectedHexBg = '#a5f5a5';
var $elm$svg$Svg$svg = $elm$svg$Svg$trustedNode('svg');
var $author$project$Traveller$toViewBox = F2(
	function (hexScale, _v0) {
		var x = _v0.x;
		var y = _v0.y;
		return function (_v1) {
			var x_ = _v1.a;
			var y_ = _v1.b;
			return $elm$core$String$fromFloat(x_) + (' ' + $elm$core$String$fromFloat(y_));
		}(
			A2(
				$author$project$Traveller$HexGeometry$calcVisualOrigin,
				hexScale,
				{col: x, row: y}));
	});
var $elm$svg$Svg$Attributes$viewBox = _VirtualDom_attribute('viewBox');
var $author$project$Traveller$HexGeometry$hexapointsBuilder = F3(
	function (xOrigin, yOrigin, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return $elm$core$String$fromFloat(xOrigin + x) + (',' + $elm$core$String$fromFloat(yOrigin + y));
	});
var $author$project$Traveller$HexGeometry$convertRawHexagonPoints = F2(
	function (_v0, points) {
		var xOrigin = _v0.a;
		var yOrigin = _v0.b;
		return A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$map,
				A2($author$project$Traveller$HexGeometry$hexapointsBuilder, xOrigin, yOrigin),
				points));
	});
var $elm$virtual_dom$VirtualDom$lazy7 = _VirtualDom_lazy7;
var $elm$svg$Svg$Lazy$lazy7 = $elm$virtual_dom$VirtualDom$lazy7;
var $elm$virtual_dom$VirtualDom$lazy8 = _VirtualDom_lazy8;
var $elm$svg$Svg$Lazy$lazy8 = $elm$virtual_dom$VirtualDom$lazy8;
var $author$project$Traveller$HoveringHex = function (a) {
	return {$: 'HoveringHex', a: a};
};
var $author$project$Traveller$MapMouseDown = function (a) {
	return {$: 'MapMouseDown', a: a};
};
var $author$project$Traveller$MapMouseMove = function (a) {
	return {$: 'MapMouseMove', a: a};
};
var $author$project$Traveller$MapMouseUp = {$: 'MapMouseUp'};
var $author$project$Traveller$ViewingHex = function (a) {
	return {$: 'ViewingHex', a: a};
};
var $elm$svg$Svg$circle = $elm$svg$Svg$trustedNode('circle');
var $elm$svg$Svg$Attributes$cx = _VirtualDom_attribute('cx');
var $elm$svg$Svg$Attributes$cy = _VirtualDom_attribute('cy');
var $elm$svg$Svg$Attributes$r = _VirtualDom_attribute('r');
var $author$project$Traveller$HexGeometry$defaultHexSize = 40;
var $author$project$Traveller$HexGeometry$scaleAttr = F2(
	function (hexSize, _default) {
		return _default * A2($elm$core$Basics$min, 1, hexSize / $author$project$Traveller$HexGeometry$defaultHexSize);
	});
var $author$project$Traveller$drawStar = F5(
	function (starX, starY, radius, size, starColor) {
		return A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx(
					$elm$core$String$fromFloat(starX)),
					$elm$svg$Svg$Attributes$cy(
					$elm$core$String$fromFloat(starY)),
					$elm$svg$Svg$Attributes$r(
					$elm$core$String$fromFloat(
						A2($author$project$Traveller$HexGeometry$scaleAttr, size, radius))),
					$elm$svg$Svg$Attributes$fill(starColor),
					$elm$svg$Svg$Attributes$style('filter: drop-shadow( 2px 2px 2px rgba(0, 0, 0, .25))')
				]),
			_List_Nil);
	});
var $elm$svg$Svg$Attributes$fontSize = _VirtualDom_attribute('font-size');
var $elm$svg$Svg$g = $elm$svg$Svg$trustedNode('g');
var $author$project$Traveller$gasGiantSI = 5;
var $author$project$Traveller$SolarSystemStars$getStarTypeData = function (_v0) {
	var starTypeData = _v0.a;
	return starTypeData;
};
var $elm$core$String$pad = F3(
	function (n, _char, string) {
		var half = (n - $elm$core$String$length(string)) / 2;
		return _Utils_ap(
			A2(
				$elm$core$String$repeat,
				$elm$core$Basics$ceiling(half),
				$elm$core$String$fromChar(_char)),
			_Utils_ap(
				string,
				A2(
					$elm$core$String$repeat,
					$elm$core$Basics$floor(half),
					$elm$core$String$fromChar(_char))));
	});
var $author$project$Traveller$HexAddress$hexLabel = function (hex) {
	var sectorHex = $author$project$Traveller$HexAddress$toSectorAddress(hex);
	return _Utils_ap(
		A3(
			$elm$core$String$pad,
			2,
			_Utils_chr('0'),
			$elm$core$String$fromInt(sectorHex.x + 1)),
		A3(
			$elm$core$String$pad,
			2,
			_Utils_chr('0'),
			$elm$core$String$fromInt(sectorHex.y + 1)));
};
var $author$project$Traveller$SolarSystemStars$isBrownDwarfType = function (theStar) {
	return A2(
		$elm$core$List$any,
		function (a) {
			return _Utils_eq(a, theStar.stellarType);
		},
		_List_fromArray(
			['D', 'Y', 'T', 'L']));
};
var $elm$virtual_dom$VirtualDom$lazy5 = _VirtualDom_lazy5;
var $elm$svg$Svg$Lazy$lazy5 = $elm$virtual_dom$VirtualDom$lazy5;
var $elm$svg$Svg$Events$on = $elm$html$Html$Events$on;
var $elm$svg$Svg$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$svg$Svg$Events$onMouseOver = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseover',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$svg$Svg$Events$onMouseUp = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseup',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Traveller$planetoidSI = 6;
var $elm$svg$Svg$Attributes$class = _VirtualDom_attribute('class');
var $elm$svg$Svg$polygon = $elm$svg$Svg$trustedNode('polygon');
var $author$project$Traveller$renderPolygon = F2(
	function (points_, fill) {
		var strokeWidth = _Utils_eq(fill, $author$project$Traveller$currentAddressHexBg) ? '2' : '1';
		var hexColour = _Utils_eq(fill, $author$project$Traveller$currentAddressHexBg) ? $author$project$Traveller$routeHexBg : fill;
		var borderColour = _Utils_eq(fill, $author$project$Traveller$currentAddressHexBg) ? $author$project$Traveller$currentAddressHexBg : '#CCCCCC';
		return A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points(points_),
					$elm$svg$Svg$Attributes$fill(hexColour),
					$elm$svg$Svg$Attributes$stroke(borderColour),
					$elm$svg$Svg$Attributes$strokeWidth(strokeWidth),
					$elm$svg$Svg$Attributes$pointerEvents('visiblePainted'),
					$elm$svg$Svg$Attributes$class('hex-hover')
				]),
			_List_Nil);
	});
var $elm$core$Basics$degrees = function (angleInDegrees) {
	return (angleInDegrees * $elm$core$Basics$pi) / 180;
};
var $author$project$Traveller$HexGeometry$rotatePoint = F5(
	function (hexSize, idx, _v0, degrees_, distance) {
		var x_ = _v0.a;
		var y_ = _v0.b;
		var rads = $elm$core$Basics$degrees((idx * degrees_) - 30);
		var sinTheta = $elm$core$Basics$sin(rads);
		var cosTheta = $elm$core$Basics$cos(rads);
		return _Utils_Tuple2(
			(x_ + (A2($author$project$Traveller$HexGeometry$scaleAttr, hexSize, distance) * cosTheta)) - (0 * sinTheta),
			(y_ + (A2($author$project$Traveller$HexGeometry$scaleAttr, hexSize, distance) * sinTheta)) + (0 * cosTheta));
	});
var $author$project$Traveller$StarColour$starColourRGB = function (colour) {
	if (colour.$ === 'Just') {
		switch (colour.a.$) {
			case 'Blue':
				var _v1 = colour.a;
				return '#000077';
			case 'BlueWhite':
				var _v2 = colour.a;
				return '#87cefa';
			case 'White':
				var _v3 = colour.a;
				return '#FFFFFF';
			case 'YellowWhite':
				var _v4 = colour.a;
				return '#ffffe0';
			case 'Yellow':
				var _v5 = colour.a;
				return '#ffff00';
			case 'LightOrange':
				var _v6 = colour.a;
				return '#ffbf00';
			case 'OrangeRed':
				var _v7 = colour.a;
				return '#ff4500';
			case 'Red':
				var _v8 = colour.a;
				return '#ff0000';
			case 'Brown':
				var _v9 = colour.a;
				return '#f4a460';
			default:
				var _v10 = colour.a;
				return '#800000';
		}
	} else {
		return '#000000';
	}
};
var $author$project$Traveller$terrestrialSI = 6;
var $elm$svg$Svg$tspan = $elm$svg$Svg$trustedNode('tspan');
var $author$project$Traveller$renderHexWithStar = F8(
	function (starSystem, hexColour, hexAddrX, hexAddrY, vox, voy, size, hexapointsStr) {
		var si = starSystem.surveyIndex;
		var showStar = starSystem.surveyIndex > 0;
		var hexAddress = A2($author$project$Traveller$HexAddress$HexAddress, hexAddrX, hexAddrY);
		return A2(
			$elm$svg$Svg$g,
			_List_fromArray(
				[
					$elm$svg$Svg$Events$onMouseOver(
					$author$project$Traveller$HoveringHex(hexAddress)),
					$elm$svg$Svg$Events$onClick(
					$author$project$Traveller$ViewingHex(hexAddress)),
					$elm$svg$Svg$Events$onMouseUp($author$project$Traveller$MapMouseUp),
					A2(
					$elm$svg$Svg$Events$on,
					'mousedown',
					$author$project$Traveller$mouseDownDecoder($author$project$Traveller$MapMouseDown)),
					A2(
					$elm$svg$Svg$Events$on,
					'mousemove',
					$author$project$Traveller$mouseMoveDecoder($author$project$Traveller$MapMouseMove)),
					$elm$svg$Svg$Attributes$style('cursor: pointer; user-select: none')
				]),
			_List_fromArray(
				[
					A3($elm$svg$Svg$Lazy$lazy2, $author$project$Traveller$renderPolygon, hexapointsStr, hexColour),
					function () {
					if (showStar) {
						var primaryPos = _Utils_Tuple2(vox, voy);
						var isKnown = function (theStar) {
							return A3($elm$core$Basics$composeR, $author$project$Traveller$SolarSystemStars$getStarTypeData, $author$project$Traveller$SolarSystemStars$isBrownDwarfType, theStar) ? (starSystem.surveyIndex >= 4) : (starSystem.surveyIndex >= 1);
						};
						var generateStar = F2(
							function (idx, starType) {
								var starData = $author$project$Traveller$SolarSystemStars$getStarTypeData(starType);
								var _v0 = (!idx) ? _Utils_Tuple2(vox, voy) : A5($author$project$Traveller$HexGeometry$rotatePoint, size, idx + 2, primaryPos, 60, 20);
								var sx = _v0.a;
								var sy = _v0.b;
								var _v1 = starData.companion;
								if (_v1.$ === 'Just') {
									var companion = _v1.a;
									var compStarData = $author$project$Traveller$SolarSystemStars$getStarTypeData(companion);
									var _v2 = _Utils_Tuple2(sx - 5, sy);
									var cx = _v2.a;
									var cy = _v2.b;
									return A2(
										$elm$svg$Svg$g,
										_List_Nil,
										_List_fromArray(
											[
												A6(
												$elm$svg$Svg$Lazy$lazy5,
												$author$project$Traveller$drawStar,
												sx,
												sy,
												7,
												size,
												$author$project$Traveller$StarColour$starColourRGB(starData.colour)),
												A6(
												$elm$svg$Svg$Lazy$lazy5,
												$author$project$Traveller$drawStar,
												cx,
												cy,
												3,
												size,
												$author$project$Traveller$StarColour$starColourRGB(compStarData.colour))
											]));
								} else {
									return A6(
										$elm$svg$Svg$Lazy$lazy5,
										$author$project$Traveller$drawStar,
										sx,
										sy,
										7,
										size,
										$author$project$Traveller$StarColour$starColourRGB(starData.colour));
								}
							});
						return A2(
							$elm$svg$Svg$g,
							_List_Nil,
							A2(
								$elm$core$List$indexedMap,
								$elm$svg$Svg$Lazy$lazy2(generateStar),
								A2($elm$core$List$filter, isKnown, starSystem.stars)));
					} else {
						return A2(
							$elm$svg$Svg$text_,
							_List_fromArray(
								[
									$elm$svg$Svg$Attributes$x(
									$elm$core$String$fromInt(vox)),
									$elm$svg$Svg$Attributes$y(
									$elm$core$String$fromInt(
										voy - $elm$core$Basics$floor(size * 0.65))),
									$elm$svg$Svg$Attributes$fontSize(
									(size > 15) ? '9' : '5'),
									$elm$svg$Svg$Attributes$textAnchor('middle'),
									$elm$svg$Svg$Attributes$fontFamily('Tomorrow'),
									$elm$svg$Svg$Attributes$fontWeight('400')
								]),
							_List_fromArray(
								[
									$elm$svg$Svg$text(
									$author$project$Traveller$HexAddress$hexLabel(hexAddress))
								]));
					}
				}(),
					showStar ? A2(
					$elm$svg$Svg$g,
					_List_Nil,
					_List_fromArray(
						[
							A2(
							$elm$svg$Svg$text_,
							_List_fromArray(
								[
									$elm$svg$Svg$Attributes$x(
									$elm$core$String$fromInt(vox)),
									$elm$svg$Svg$Attributes$y(
									$elm$core$String$fromInt(
										voy - $elm$core$Basics$floor(size * 0.65))),
									$elm$svg$Svg$Attributes$fontSize(
									(size > 15) ? '9' : '5'),
									$elm$svg$Svg$Attributes$textAnchor('middle'),
									$elm$svg$Svg$Attributes$fontFamily('Tomorrow'),
									$elm$svg$Svg$Attributes$fontWeight('400')
								]),
							_List_fromArray(
								[
									$elm$svg$Svg$text(
									$author$project$Traveller$HexAddress$hexLabel(hexAddress))
								])),
							A2(
							$elm$svg$Svg$text_,
							_List_fromArray(
								[
									$elm$svg$Svg$Attributes$x(
									$elm$core$String$fromInt(vox)),
									$elm$svg$Svg$Attributes$y(
									$elm$core$String$fromInt(
										(voy + $elm$core$Basics$floor(size * 0.8)) - 1)),
									$elm$svg$Svg$Attributes$fontSize('10'),
									$elm$svg$Svg$Attributes$textAnchor('middle')
								]),
							function () {
								var showIfKnown = F2(
									function (req, value) {
										return (_Utils_cmp(si, req) > -1) ? $elm$core$String$fromInt(value) : '?';
									});
								return _List_fromArray(
									[
										A2(
										$elm$svg$Svg$tspan,
										_List_fromArray(
											[
												$elm$svg$Svg$Attributes$fill('#809076'),
												$elm$svg$Svg$Attributes$fontWeight('800')
											]),
										_List_fromArray(
											[
												$elm$svg$Svg$text(
												A2(showIfKnown, $author$project$Traveller$terrestrialSI, starSystem.terrestrialPlanetCount))
											])),
										$elm$svg$Svg$text('–'),
										A2(
										$elm$svg$Svg$tspan,
										_List_fromArray(
											[
												$elm$svg$Svg$Attributes$fill('#68B976'),
												$elm$svg$Svg$Attributes$fontWeight('800')
											]),
										_List_fromArray(
											[
												$elm$svg$Svg$text(
												A2(showIfKnown, $author$project$Traveller$planetoidSI, starSystem.planetoidBeltCount))
											])),
										$elm$svg$Svg$text('–'),
										A2(
										$elm$svg$Svg$tspan,
										_List_fromArray(
											[
												$elm$svg$Svg$Attributes$fill('#109076'),
												$elm$svg$Svg$Attributes$fontWeight('800')
											]),
										_List_fromArray(
											[
												$elm$svg$Svg$text(
												A2(showIfKnown, $author$project$Traveller$gasGiantSI, starSystem.gasGiantCount))
											]))
									]);
							}())
						])) : $elm$svg$Svg$text('')
				]));
	});
var $author$project$Traveller$viewHexEmpty = F7(
	function (hx, hy, x, y, size, childSvgTxt, hexColour) {
		var origin = _Utils_Tuple2(x, y);
		var hexAddress = A2($author$project$Traveller$HexAddress$HexAddress, hx, hy);
		var childSvg = A2(
			$elm$svg$Svg$text_,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x(
					$elm$core$String$fromInt(x)),
					$elm$svg$Svg$Attributes$y(
					$elm$core$String$fromInt(y)),
					$elm$svg$Svg$Attributes$fontSize('10'),
					$elm$svg$Svg$Attributes$textAnchor('middle')
				]),
			_List_fromArray(
				[
					$elm$svg$Svg$text(childSvgTxt)
				]));
		return A2(
			$elm$svg$Svg$g,
			_List_fromArray(
				[
					$elm$svg$Svg$Events$onMouseOver(
					$author$project$Traveller$HoveringHex(hexAddress)),
					$elm$svg$Svg$Events$onClick(
					$author$project$Traveller$ViewingHex(hexAddress)),
					$elm$svg$Svg$Events$onMouseUp($author$project$Traveller$MapMouseUp),
					A2(
					$elm$svg$Svg$Events$on,
					'mousedown',
					$author$project$Traveller$mouseDownDecoder($author$project$Traveller$MapMouseDown)),
					A2(
					$elm$svg$Svg$Events$on,
					'mousemove',
					$author$project$Traveller$mouseMoveDecoder($author$project$Traveller$MapMouseMove)),
					$elm$svg$Svg$Attributes$style('cursor: pointer; user-select: none'),
					$elm$svg$Svg$Attributes$id(
					'rendered-hex:' + $author$project$Traveller$HexAddress$toKey(hexAddress))
				]),
			_List_fromArray(
				[
					A3(
					$elm$svg$Svg$Lazy$lazy2,
					$author$project$Traveller$renderPolygon,
					A2(
						$elm$core$String$join,
						' ',
						A2($author$project$Traveller$HexGeometry$hexagonPoints, origin, size)),
					hexColour),
					A2(
					$elm$svg$Svg$text_,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$x(
							$elm$core$String$fromInt(x)),
							$elm$svg$Svg$Attributes$y(
							$elm$core$String$fromInt(
								y - $elm$core$Basics$floor(size * 0.65))),
							$elm$svg$Svg$Attributes$fontSize(
							(size > 15) ? '9' : '5'),
							$elm$svg$Svg$Attributes$textAnchor('middle'),
							$elm$svg$Svg$Attributes$fontFamily('Tomorrow'),
							$elm$svg$Svg$Attributes$fontWeight('400')
						]),
					_List_fromArray(
						[
							$elm$svg$Svg$text(
							$author$project$Traveller$HexAddress$hexLabel(hexAddress))
						])),
					childSvg
				]));
	});
var $author$project$Traveller$viewHex = F7(
	function (hexSize, solarSystemDict, hexAddress, vox, voy, hexColour, rawHexaPoints) {
		var viewEmptyHelper = function (txt) {
			return A8($elm$svg$Svg$Lazy$lazy7, $author$project$Traveller$viewHexEmpty, hexAddress.x, hexAddress.y, vox, voy, hexSize, txt, hexColour);
		};
		var remoteSolarSystem = A2(
			$elm$core$Dict$get,
			$author$project$Traveller$HexAddress$toKey(hexAddress),
			solarSystemDict);
		var hexSVG = function () {
			if (remoteSolarSystem.$ === 'Just') {
				switch (remoteSolarSystem.a.$) {
					case 'LoadedSolarSystem':
						var loadedSystem = remoteSolarSystem.a.a;
						var hexapointsStr = A2(
							$author$project$Traveller$HexGeometry$convertRawHexagonPoints,
							_Utils_Tuple2(vox, voy),
							rawHexaPoints);
						return A9($elm$svg$Svg$Lazy$lazy8, $author$project$Traveller$renderHexWithStar, loadedSystem, hexColour, hexAddress.x, hexAddress.y, vox, voy, hexSize, hexapointsStr);
					case 'LoadingSolarSystem':
						var _v1 = remoteSolarSystem.a;
						return viewEmptyHelper('Loading...');
					case 'FailedSolarSystem':
						var httpError = remoteSolarSystem.a.a;
						return viewEmptyHelper('Failed.');
					case 'LoadedEmptyHex':
						var _v2 = remoteSolarSystem.a;
						return viewEmptyHelper('');
					default:
						var failedSolarSystem = remoteSolarSystem.a.a;
						return A8($elm$svg$Svg$Lazy$lazy7, $author$project$Traveller$viewHexEmpty, hexAddress.x, hexAddress.y, vox, voy, hexSize, 'Star Failed.', '#aaaaaa');
				}
			} else {
				return viewEmptyHelper('');
			}
		}();
		return hexSVG;
	});
var $elm$svg$Svg$Attributes$width = _VirtualDom_attribute('width');
var $author$project$Traveller$viewHexes = F7(
	function (_v0, _v1, _v2, _v3, hexSize, maybeSelectedHex, isReferee) {
		var upperLeftHex = _v0.a.upperLeftHex;
		var lowerRightHex = _v0.a.lowerRightHex;
		var rawHexaPoints = _v0.b;
		var svgWidth = _v1.svgWidth;
		var svgHeight = _v1.svgHeight;
		var maxAcross = _v1.maxAcross;
		var maxTall = _v1.maxTall;
		var solarSystemDict = _v2.solarSystemDict;
		var hexColours = _v2.hexColours;
		var regionLabels = _v2.regionLabels;
		var route = _v3.a;
		var currentAddress = _v3.b;
		var viewSingleHex = function (hexAddr) {
			var hexKey = $author$project$Traveller$HexAddress$toKey(hexAddr);
			var hexColour = function () {
				if (_Utils_eq(hexAddr, currentAddress)) {
					return $author$project$Traveller$currentAddressHexBg;
				} else {
					if (A2($author$project$Traveller$isOnRoute, route, hexAddr)) {
						return $author$project$Traveller$routeHexBg;
					} else {
						var _v9 = A2($elm$core$Dict$get, hexKey, hexColours);
						if (_v9.$ === 'Just') {
							var color = _v9.a;
							return $noahzgordon$elm_color_extra$Color$Convert$colorToHex(color);
						} else {
							if (maybeSelectedHex.$ === 'Just') {
								var selectedHex = maybeSelectedHex.a;
								return _Utils_eq(selectedHex, hexAddr) ? $author$project$Traveller$selectedHexBg : A3($author$project$Traveller$hexBackgroundColour, isReferee, hexKey, solarSystemDict);
							} else {
								return A3($author$project$Traveller$hexBackgroundColour, isReferee, hexKey, solarSystemDict);
							}
						}
					}
				}
			}();
			var _v8 = A2(
				$author$project$Traveller$HexGeometry$calcVisualOrigin,
				hexSize,
				{col: hexAddr.x, row: hexAddr.y});
			var vox = _v8.a;
			var voy = _v8.b;
			return _Utils_Tuple2(
				hexAddr,
				A7($author$project$Traveller$viewHex, hexSize, solarSystemDict, hexAddr, vox, voy, hexColour, rawHexaPoints));
		};
		var renderCurrentAddressOutline = function (ca) {
			var locationOrigin = A3(
				$elm$core$Tuple$mapBoth,
				$elm$core$Basics$toFloat,
				$elm$core$Basics$toFloat,
				A2(
					$author$project$Traveller$HexGeometry$calcVisualOrigin,
					hexSize,
					{col: ca.x - upperLeftHex.x, row: upperLeftHex.y - ca.y}));
			var points = function () {
				var _v7 = A2($author$project$Traveller$HexGeometry$hexagonPoints, locationOrigin, hexSize);
				if (_v7.b) {
					var first = _v7.a;
					var points_ = _v7.b;
					return _Utils_ap(
						A2($elm$core$List$cons, first, points_),
						_List_fromArray(
							[first]));
				} else {
					var other = _v7;
					return other;
				}
			}();
			return A3(
				$elm$svg$Svg$Lazy$lazy2,
				$author$project$Traveller$renderPolyline,
				A2($elm$core$String$join, ' ', points),
				$author$project$Traveller$currentAddressHexBg);
		};
		var hexRange = A3(
			$author$project$Traveller$HexAddress$betweenWithMax,
			A2(
				$author$project$Traveller$HexAddress$shiftAddressBy,
				{deltaX: -1, deltaY: -1},
				upperLeftHex),
			lowerRightHex,
			{maxAcross: maxAcross, maxTall: maxTall});
		return function () {
			var widthString = $elm$core$String$fromFloat(svgWidth);
			var heightString = $elm$core$String$fromFloat(svgHeight);
			return $elm$svg$Svg$svg(
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$width(widthString),
						$elm$svg$Svg$Attributes$height(heightString),
						$elm$svg$Svg$Attributes$id('hexmap'),
						$elm$svg$Svg$Events$onMouseOut($author$project$Traveller$MapMouseLeave),
						$elm$svg$Svg$Attributes$viewBox(
						A2($author$project$Traveller$toViewBox, hexSize, upperLeftHex) + (' ' + (widthString + (' ' + heightString))))
					]));
		}()(
			function (_v5) {
				var hexSvgsWithHexAddress = _v5.a;
				var labels = _v5.b;
				var singlePolyHex = renderCurrentAddressOutline(currentAddress);
				var keyedHexes = A3(
					$elm$svg$Svg$Keyed$node,
					'g',
					_List_Nil,
					A2(
						$elm$core$List$map,
						function (_v6) {
							var addr = _v6.a;
							var hex = _v6.b;
							return _Utils_Tuple2(
								$author$project$Traveller$HexAddress$toKey(addr),
								hex);
						},
						hexSvgsWithHexAddress));
				var ulSector = $author$project$Traveller$HexAddress$toSectorAddress(upperLeftHex);
				var lrSector = $author$project$Traveller$HexAddress$toSectorAddress(lowerRightHex);
				var sectorOutlines = A2(
					$elm$core$List$concatMap,
					function (sx) {
						return A2(
							$elm$core$List$map,
							function (sy) {
								return A2(
									$author$project$Traveller$renderSectorOutline,
									hexSize,
									_Utils_update(
										ulSector,
										{sectorX: sx, sectorY: sy}));
							},
							A2(
								$elm$core$List$range,
								A2($elm$core$Basics$min, ulSector.sectorY, lrSector.sectorY),
								A2($elm$core$Basics$max, ulSector.sectorY, lrSector.sectorY)));
					},
					A2(
						$elm$core$List$range,
						A2($elm$core$Basics$min, ulSector.sectorX, lrSector.sectorX),
						A2($elm$core$Basics$max, ulSector.sectorX, lrSector.sectorX)));
				return _Utils_ap(
					_List_fromArray(
						[keyedHexes]),
					_Utils_ap(
						sectorOutlines,
						_Utils_ap(
							_List_fromArray(
								[singlePolyHex]),
							labels)));
			}(
				function (hexSvgsWithHexAddress) {
					var labelPos = function (hexAddr) {
						return A2(
							$author$project$Traveller$HexGeometry$calcVisualOrigin,
							hexSize,
							{col: hexAddr.x, row: hexAddr.y});
					};
					var renderRegionLabel = function (hexAddress) {
						return A2(
							$elm$core$Maybe$map,
							function (name) {
								var _v4 = labelPos(hexAddress);
								var x = _v4.a;
								var y = _v4.b;
								return A4($elm$html$Html$Lazy$lazy3, $author$project$Traveller$regionLabel, x, y, name);
							},
							A2(
								$elm$core$Dict$get,
								$author$project$Traveller$HexAddress$toKey(hexAddress),
								regionLabels));
					};
					var labels = A2($elm$core$List$filterMap, renderRegionLabel, hexRange);
					return _Utils_Tuple2(hexSvgsWithHexAddress, labels);
				}(
					A2($elm$core$List$map, viewSingleHex, hexRange))));
	});
var $author$project$Traveller$viewHexMap = function (model) {
	var svgWidth = model.viewport.viewport.viewport.width - 420;
	var svgHeight = model.viewport.viewport.viewport.height - $author$project$Traveller$consoleTitleHeight;
	var _v0 = function () {
		var _v1 = A2(
			$author$project$Traveller$HexGeometry$calcVisualOrigin,
			model.hexScale,
			{col: 2, row: 1});
		var right_x = _v1.a;
		var _v2 = A2(
			$author$project$Traveller$HexGeometry$calcVisualOrigin,
			model.hexScale,
			{col: 1, row: 1});
		var left_x = _v2.a;
		var left_y = _v2.b;
		var _v3 = A2(
			$author$project$Traveller$HexGeometry$calcVisualOrigin,
			model.hexScale,
			{col: 1, row: 2});
		var down_y = _v3.b;
		return _Utils_Tuple2(
			$elm$core$Basics$abs(left_x - right_x),
			$elm$core$Basics$abs(down_y - left_y));
	}();
	var visualHexWidth = _v0.a;
	var visualHexHeight = _v0.b;
	var _v4 = function () {
		var _v5 = model.viewport.hexmapViewport;
		if (_v5.$ === 'Nothing') {
			return _Utils_Tuple2(10000, 10000);
		} else {
			if (_v5.a.$ === 'Ok') {
				var hvp = _v5.a.a;
				return _Utils_Tuple2(
					$elm$core$Basics$floor((hvp.viewport.width / visualHexWidth) + 2),
					$elm$core$Basics$floor((hvp.viewport.height / visualHexHeight) + 2));
			} else {
				return _Utils_Tuple2(10000, 10000);
			}
		}
	}();
	var maxAcross = _v4.a;
	var maxTall = _v4.b;
	return $mdgriffith$elm_ui$Element$html(
		A7(
			$author$project$Traveller$viewHexes,
			_Utils_Tuple2(model.hexRect, model.rawHexaPoints),
			{maxAcross: maxAcross, maxTall: maxTall, svgHeight: svgHeight, svgWidth: svgWidth},
			{hexColours: model.hexColours, regionLabels: model.regionLabels, solarSystemDict: model.solarSystems},
			_Utils_Tuple2(model.route, model.currentAddress),
			model.hexScale,
			model.selectedHex,
			model.isReferee));
};
var $mdgriffith$elm_ui$Internal$Model$Right = {$: 'Right'};
var $mdgriffith$elm_ui$Element$alignRight = $mdgriffith$elm_ui$Internal$Model$AlignX($mdgriffith$elm_ui$Internal$Model$Right);
var $mdgriffith$elm_ui$Internal$Model$CenterY = {$: 'CenterY'};
var $mdgriffith$elm_ui$Element$centerY = $mdgriffith$elm_ui$Internal$Model$AlignY($mdgriffith$elm_ui$Internal$Model$CenterY);
var $mdgriffith$elm_ui$Internal$Model$paddingName = F4(
	function (top, right, bottom, left) {
		return 'pad-' + ($elm$core$String$fromInt(top) + ('-' + ($elm$core$String$fromInt(right) + ('-' + ($elm$core$String$fromInt(bottom) + ('-' + $elm$core$String$fromInt(left)))))));
	});
var $mdgriffith$elm_ui$Element$paddingEach = function (_v0) {
	var top = _v0.top;
	var right = _v0.right;
	var bottom = _v0.bottom;
	var left = _v0.left;
	if (_Utils_eq(top, right) && (_Utils_eq(top, bottom) && _Utils_eq(top, left))) {
		var topFloat = top;
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$padding,
			A5(
				$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
				'p-' + $elm$core$String$fromInt(top),
				topFloat,
				topFloat,
				topFloat,
				topFloat));
	} else {
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$padding,
			A5(
				$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
				A4($mdgriffith$elm_ui$Internal$Model$paddingName, top, right, bottom, left),
				top,
				right,
				bottom,
				left));
	}
};
var $mdgriffith$elm_ui$Internal$Model$boxShadowClass = function (shadow) {
	return $elm$core$String$concat(
		_List_fromArray(
			[
				shadow.inset ? 'box-inset' : 'box-',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.offset.a) + 'px',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.offset.b) + 'px',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.blur) + 'px',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.size) + 'px',
				$mdgriffith$elm_ui$Internal$Model$formatColorClass(shadow.color)
			]));
};
var $mdgriffith$elm_ui$Internal$Flag$shadows = $mdgriffith$elm_ui$Internal$Flag$flag(19);
var $mdgriffith$elm_ui$Element$Border$shadow = function (almostShade) {
	var shade = {blur: almostShade.blur, color: almostShade.color, inset: false, offset: almostShade.offset, size: almostShade.size};
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$shadows,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Single,
			$mdgriffith$elm_ui$Internal$Model$boxShadowClass(shade),
			'box-shadow',
			$mdgriffith$elm_ui$Internal$Model$formatBoxShadow(shade)));
};
var $elm$core$Array$fromListHelp = F3(
	function (list, nodeList, nodeListSize) {
		fromListHelp:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, list);
			var jsArray = _v0.a;
			var remainingItems = _v0.b;
			if (_Utils_cmp(
				$elm$core$Elm$JsArray$length(jsArray),
				$elm$core$Array$branchFactor) < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					true,
					{nodeList: nodeList, nodeListSize: nodeListSize, tail: jsArray});
			} else {
				var $temp$list = remainingItems,
					$temp$nodeList = A2(
					$elm$core$List$cons,
					$elm$core$Array$Leaf(jsArray),
					nodeList),
					$temp$nodeListSize = nodeListSize + 1;
				list = $temp$list;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue fromListHelp;
			}
		}
	});
var $elm$core$Array$fromList = function (list) {
	if (!list.b) {
		return $elm$core$Array$empty;
	} else {
		return A3($elm$core$Array$fromListHelp, list, _List_Nil, 0);
	}
};
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$core$Array$bitMask = 4294967295 >>> (32 - $elm$core$Array$shiftStep);
var $elm$core$Elm$JsArray$unsafeGet = _JsArray_unsafeGet;
var $elm$core$Array$getHelp = F3(
	function (shift, index, tree) {
		getHelp:
		while (true) {
			var pos = $elm$core$Array$bitMask & (index >>> shift);
			var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (_v0.$ === 'SubTree') {
				var subTree = _v0.a;
				var $temp$shift = shift - $elm$core$Array$shiftStep,
					$temp$index = index,
					$temp$tree = subTree;
				shift = $temp$shift;
				index = $temp$index;
				tree = $temp$tree;
				continue getHelp;
			} else {
				var values = _v0.a;
				return A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, values);
			}
		}
	});
var $elm$core$Array$tailIndex = function (len) {
	return (len >>> 5) << 5;
};
var $elm$core$Array$get = F2(
	function (index, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? $elm$core$Maybe$Nothing : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? $elm$core$Maybe$Just(
			A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, tail)) : $elm$core$Maybe$Just(
			A3($elm$core$Array$getHelp, startShift, index, tree)));
	});
var $author$project$Traveller$UI$groupAttrs = _List_fromArray(
	[
		A2($mdgriffith$elm_ui$Element$paddingXY, 5, 0),
		$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
	]);
var $elm_community$list_extra$List$Extra$scanl = F3(
	function (f, b, xs) {
		var scan1 = F2(
			function (x, accAcc) {
				if (accAcc.b) {
					var acc = accAcc.a;
					return A2(
						$elm$core$List$cons,
						A2(f, x, acc),
						accAcc);
				} else {
					return _List_Nil;
				}
			});
		return $elm$core$List$reverse(
			A3(
				$elm$core$List$foldl,
				scan1,
				_List_fromArray(
					[b]),
				xs));
	});
var $mdgriffith$elm_ui$Internal$Flag$fontWeight = $mdgriffith$elm_ui$Internal$Flag$flag(13);
var $mdgriffith$elm_ui$Element$Font$bold = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$fontWeight, $mdgriffith$elm_ui$Internal$Style$classes.bold);
var $avh4$elm_color$Color$scaleFrom255 = function (c) {
	return c / 255;
};
var $avh4$elm_color$Color$rgb255 = F3(
	function (r, g, b) {
		return A4(
			$avh4$elm_color$Color$RgbaSpace,
			$avh4$elm_color$Color$scaleFrom255(r),
			$avh4$elm_color$Color$scaleFrom255(g),
			$avh4$elm_color$Color$scaleFrom255(b),
			1.0);
	});
var $author$project$Traveller$UI$deepnightColor = A3($avh4$elm_color$Color$rgb255, 223, 127, 51);
var $author$project$Traveller$UI$uiDeepnightColorFontColour = $mdgriffith$elm_ui$Element$Font$color(
	$author$project$Traveller$UI$colorToElementColor($author$project$Traveller$UI$deepnightColor));
var $author$project$Traveller$UI$headerAttrs = _List_fromArray(
	[
		$author$project$Traveller$UI$uiDeepnightColorFontColour,
		$mdgriffith$elm_ui$Element$Font$size(14),
		$mdgriffith$elm_ui$Element$Font$bold,
		$mdgriffith$elm_ui$Element$alignTop
	]);
var $author$project$Traveller$UI$valueAttrs = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$Font$size(14),
		$mdgriffith$elm_ui$Element$alignTop
	]);
var $author$project$Traveller$UI$zeroEach = {bottom: 0, left: 0, right: 0, top: 0};
var $author$project$Traveller$UI$textDisplayMedium = F2(
	function (lbl, val) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$el,
					_Utils_ap(
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width(
								$mdgriffith$elm_ui$Element$px(110)),
								$mdgriffith$elm_ui$Element$paddingEach(
								_Utils_update(
									$author$project$Traveller$UI$zeroEach,
									{top: 5}))
							]),
						$author$project$Traveller$UI$headerAttrs),
					$mdgriffith$elm_ui$Element$text(lbl)),
					A2(
					$mdgriffith$elm_ui$Element$row,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$spacing(0)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							_Utils_ap(
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$alignTop,
										$mdgriffith$elm_ui$Element$spacing(0),
										$mdgriffith$elm_ui$Element$padding(0)
									]),
								$author$project$Traveller$UI$valueAttrs),
							$author$project$Traveller$UI$monospaceText(val))
						]))
				]));
	});
var $author$project$Traveller$UI$textDisplayNarrow = F2(
	function (lbl, val) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$el,
					_Utils_ap(
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width(
								$mdgriffith$elm_ui$Element$px(90)),
								$mdgriffith$elm_ui$Element$paddingEach(
								_Utils_update(
									$author$project$Traveller$UI$zeroEach,
									{top: 5}))
							]),
						$author$project$Traveller$UI$headerAttrs),
					$mdgriffith$elm_ui$Element$text(lbl)),
					A2(
					$mdgriffith$elm_ui$Element$row,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$spacing(0)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							_Utils_ap(
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$alignTop,
										$mdgriffith$elm_ui$Element$spacing(0),
										$mdgriffith$elm_ui$Element$padding(0)
									]),
								$author$project$Traveller$UI$valueAttrs),
							$author$project$Traveller$UI$monospaceText(val))
						]))
				]));
	});
var $author$project$Traveller$AnalysisDetail$viewGasGiantAnalysisDetail = F2(
	function (timeChars, data) {
		var strings = _List_fromArray(
			[data.physical.au, data.physical.period, data.physical.inclination, data.physical.eccentricity, data.physical.mass, data.physical.diameter, data.physical.axialTilt, data.physical.moons, data.physical.hasRing]);
		var counts = $elm$core$Array$fromList(
			A3(
				$elm_community$list_extra$List$Extra$scanl,
				F2(
					function (word, total) {
						return total + $elm$core$Basics$floor(
							$elm$core$Basics$sqrt(
								$elm$core$String$length(word)));
					}),
				0,
				strings));
		var showTimeCharsTEMP = F2(
			function (index, str) {
				var offset = timeChars - A2(
					$elm$core$Maybe$withDefault,
					0,
					A2($elm$core$Array$get, index, counts));
				return (timeChars < 0) ? '' : A2($elm$core$String$left, offset, str);
			});
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_Nil,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Physical'),
							A2(
							$mdgriffith$elm_ui$Element$row,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$spacing(40),
								$author$project$Traveller$UI$groupAttrs),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'AU',
											A2(showTimeCharsTEMP, 0, data.physical.au)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Period (yrs)',
											A2(showTimeCharsTEMP, 1, data.physical.period)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Inclination',
											A2(showTimeCharsTEMP, 2, data.physical.inclination)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Eccentricity',
											A2(showTimeCharsTEMP, 3, data.physical.eccentricity))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Mass (earths)',
											A2(showTimeCharsTEMP, 4, data.physical.mass)),
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Diameter (km)',
											A2(showTimeCharsTEMP, 5, data.physical.diameter)),
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Axial Tilt',
											A2(showTimeCharsTEMP, 6, data.physical.axialTilt))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Moons',
											A2(showTimeCharsTEMP, 7, data.physical.moons)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Rings',
											A2(showTimeCharsTEMP, 8, data.physical.hasRing))
										]))
								]))
						]))
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$Paragraph = {$: 'Paragraph'};
var $mdgriffith$elm_ui$Element$paragraph = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asParagraph,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$Describe($mdgriffith$elm_ui$Internal$Model$Paragraph),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$spacing(5),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $author$project$Traveller$UI$taintTextDisplay = F2(
	function (lbl, val) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$paragraph,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$alignTop,
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$width(
									$mdgriffith$elm_ui$Element$px(100)),
								$author$project$Traveller$UI$headerAttrs),
							$mdgriffith$elm_ui$Element$text(lbl))
						])),
					A2(
					$mdgriffith$elm_ui$Element$paragraph,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$alignTop,
							$mdgriffith$elm_ui$Element$width(
							$mdgriffith$elm_ui$Element$px(530)),
							$mdgriffith$elm_ui$Element$spacing(0)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							$author$project$Traveller$UI$valueAttrs,
							$author$project$Traveller$UI$monospaceText(val))
						]))
				]));
	});
var $author$project$Traveller$UI$textDisplay = F2(
	function (lbl, val) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
					$mdgriffith$elm_ui$Element$paddingEach(
					_Utils_update(
						$author$project$Traveller$UI$zeroEach,
						{top: 5}))
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$paragraph,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$alignTop,
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$width(
									$mdgriffith$elm_ui$Element$px(150)),
								$author$project$Traveller$UI$headerAttrs),
							$mdgriffith$elm_ui$Element$text(lbl))
						])),
					A2(
					$mdgriffith$elm_ui$Element$paragraph,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
							$mdgriffith$elm_ui$Element$spacing(0)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							$author$project$Traveller$UI$valueAttrs,
							$author$project$Traveller$UI$monospaceText(val))
						]))
				]));
	});
var $author$project$Traveller$AnalysisDetail$viewPlanetoidAnalysisDetail = F2(
	function (timeChars, data) {
		var strings = _List_fromArray(
			[data.physical.au, data.physical.period, data.physical.inclination, data.physical.eccentricity, data.physical.mass, data.physical.density, data.physical.gravity, data.physical.diameter, data.physical.meanTemperature, data.physical.albedo, data.physical.axialTilt, data.physical.greenhouse, data.atmosphere.type_, data.atmosphere.bar, data.atmosphere.hazardCode, data.atmosphere.taint.subtype, data.atmosphere.taint.severity, data.atmosphere.taint.persistence, data.hydrographics.percentage, data.hydrographics.surfaceDistribution, data.life.biomass, data.life.biocomplexity, data.life.biodiversity, data.life.compatibility, data.life.habitability, data.life.sophonts]);
		var counts = $elm$core$Array$fromList(
			A3(
				$elm_community$list_extra$List$Extra$scanl,
				F2(
					function (word, total) {
						return total + $elm$core$Basics$floor(
							$elm$core$Basics$sqrt(
								$elm$core$String$length(word)));
					}),
				0,
				strings));
		var showTimeCharsTEMP = F2(
			function (index, str) {
				var offset = timeChars - A2(
					$elm$core$Maybe$withDefault,
					0,
					A2($elm$core$Array$get, index, counts));
				return (timeChars < 0) ? '' : A2($elm$core$String$left, offset, str);
			});
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_Nil,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Physical'),
							A2(
							$mdgriffith$elm_ui$Element$row,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$spacing(40),
								$author$project$Traveller$UI$groupAttrs),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'AU',
											A2(showTimeCharsTEMP, 0, data.physical.au)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Period (yrs)',
											A2(showTimeCharsTEMP, 1, data.physical.period)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Inclination',
											A2(showTimeCharsTEMP, 2, data.physical.inclination)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Eccentricity',
											A2(showTimeCharsTEMP, 3, data.physical.eccentricity))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Mass (earths)',
											A2(showTimeCharsTEMP, 4, data.physical.mass)),
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Density (earth)',
											A2(showTimeCharsTEMP, 5, data.physical.density)),
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Gravity (G)',
											A2(showTimeCharsTEMP, 6, data.physical.gravity)),
											A2(
											$author$project$Traveller$UI$textDisplayMedium,
											'Diameter (km)',
											A2(showTimeCharsTEMP, 7, data.physical.diameter))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Temperature',
											A2(showTimeCharsTEMP, 8, data.physical.meanTemperature)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Albedo',
											A2(showTimeCharsTEMP, 9, data.physical.albedo)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Axial Tilt',
											A2(showTimeCharsTEMP, 10, data.physical.axialTilt)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Greenhouse',
											A2(showTimeCharsTEMP, 11, data.physical.greenhouse))
										]))
								]))
						])),
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
							A2($mdgriffith$elm_ui$Element$paddingXY, 0, 10)
						]),
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Atmosphere'),
							A2(
							$mdgriffith$elm_ui$Element$column,
							$author$project$Traveller$UI$groupAttrs,
							_List_fromArray(
								[
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Type',
									A2(showTimeCharsTEMP, 12, data.atmosphere.type_)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'BAR',
									A2(showTimeCharsTEMP, 13, data.atmosphere.bar)),
									true ? A2(
									$author$project$Traveller$UI$textDisplay,
									'Hazard Code',
									A2(showTimeCharsTEMP, 14, data.atmosphere.hazardCode)) : $mdgriffith$elm_ui$Element$none,
									A2(
									$mdgriffith$elm_ui$Element$row,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
										]),
									_List_fromArray(
										[
											A2(
											$mdgriffith$elm_ui$Element$el,
											_List_fromArray(
												[
													$author$project$Traveller$UI$uiDeepnightColorFontColour,
													$mdgriffith$elm_ui$Element$Font$bold,
													$mdgriffith$elm_ui$Element$Font$size(14),
													$mdgriffith$elm_ui$Element$alignTop,
													$mdgriffith$elm_ui$Element$width(
													$mdgriffith$elm_ui$Element$px(50)),
													$mdgriffith$elm_ui$Element$paddingEach(
													_Utils_update(
														$author$project$Traveller$UI$zeroEach,
														{top: 5}))
												]),
											$mdgriffith$elm_ui$Element$text('Taint')),
											A2(
											$mdgriffith$elm_ui$Element$column,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
												]),
											_List_fromArray(
												[
													A2(
													$author$project$Traveller$UI$taintTextDisplay,
													'Subtype',
													A2(showTimeCharsTEMP, 15, data.atmosphere.taint.subtype)),
													A2(
													$author$project$Traveller$UI$taintTextDisplay,
													'Severity',
													A2(showTimeCharsTEMP, 16, data.atmosphere.taint.severity)),
													A2(
													$author$project$Traveller$UI$taintTextDisplay,
													'Persistence',
													A2(showTimeCharsTEMP, 17, data.atmosphere.taint.persistence))
												]))
										]))
								]))
						])),
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Element$paddingXY, 0, 10)
						]),
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Hydrographics'),
							A2(
							$mdgriffith$elm_ui$Element$column,
							$author$project$Traveller$UI$groupAttrs,
							_List_fromArray(
								[
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Percentage',
									A2(showTimeCharsTEMP, 18, data.hydrographics.percentage)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Surface Distribution',
									A2(showTimeCharsTEMP, 19, data.hydrographics.surfaceDistribution))
								]))
						])),
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Element$paddingXY, 0, 10)
						]),
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Life'),
							A2(
							$mdgriffith$elm_ui$Element$column,
							$author$project$Traveller$UI$groupAttrs,
							_List_fromArray(
								[
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Biomass',
									A2(showTimeCharsTEMP, 20, data.life.biomass)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Biocomplexity',
									A2(showTimeCharsTEMP, 21, data.life.biocomplexity)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Biodiversity',
									A2(showTimeCharsTEMP, 22, data.life.biodiversity)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Compatibilty',
									A2(showTimeCharsTEMP, 23, data.life.compatibility)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Habitability',
									A2(showTimeCharsTEMP, 24, data.life.habitability)),
									A2(
									$author$project$Traveller$UI$textDisplay,
									'Sophonts',
									A2(showTimeCharsTEMP, 25, data.life.sophonts))
								]))
						]))
				]));
	});
var $author$project$Traveller$AnalysisDetail$viewPlanetoidBeltAnalysisDetail = F2(
	function (timeChars, data) {
		var strings = _List_fromArray(
			[data.physical.au, data.physical.period, data.physical.inclination, data.physical.eccentricity, data.physical.span, data.physical.bulk, data.physical.cType, data.physical.mType, data.physical.sType, data.physical.oType]);
		var counts = $elm$core$Array$fromList(
			A3(
				$elm_community$list_extra$List$Extra$scanl,
				F2(
					function (word, total) {
						return total + $elm$core$Basics$floor(
							$elm$core$Basics$sqrt(
								$elm$core$String$length(word)));
					}),
				0,
				strings));
		var showTimeCharsTEMP = F2(
			function (index, str) {
				var offset = timeChars - A2(
					$elm$core$Maybe$withDefault,
					0,
					A2($elm$core$Array$get, index, counts));
				return (timeChars < 0) ? '' : A2($elm$core$String$left, offset, str);
			});
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_Nil,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text('Physical'),
							A2(
							$mdgriffith$elm_ui$Element$row,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$spacing(40),
								$author$project$Traveller$UI$groupAttrs),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'AU',
											A2(showTimeCharsTEMP, 0, data.physical.au)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Period (yrs)',
											A2(showTimeCharsTEMP, 1, data.physical.period)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Inclination',
											A2(showTimeCharsTEMP, 2, data.physical.inclination)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Eccentricity',
											A2(showTimeCharsTEMP, 3, data.physical.eccentricity))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Span',
											A2(showTimeCharsTEMP, 4, data.physical.span)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'Bulk',
											A2(showTimeCharsTEMP, 5, data.physical.bulk))
										])),
									A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$alignTop]),
									_List_fromArray(
										[
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'c-type',
											A2(showTimeCharsTEMP, 6, data.physical.cType)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'm-type',
											A2(showTimeCharsTEMP, 7, data.physical.mType)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											's-type',
											A2(showTimeCharsTEMP, 8, data.physical.sType)),
											A2(
											$author$project$Traveller$UI$textDisplayNarrow,
											'o-type',
											A2(showTimeCharsTEMP, 9, data.physical.oType))
										]))
								]))
						]))
				]));
	});
var $author$project$Traveller$AnalysisDetail$viewObjectAnalysisDetail = F3(
	function (timeChars, closeMsg, data) {
		var _v0 = function () {
			switch (data.$) {
				case 'AnalyisDetailTerrestialPlanet':
					var detailHeader = data.a;
					var sharedPData = data.b;
					return _Utils_Tuple2(
						detailHeader.header,
						A2($author$project$Traveller$AnalysisDetail$viewPlanetoidAnalysisDetail, timeChars, sharedPData));
				case 'AnalyisDetailPlanetoid':
					var detailHeader = data.a;
					var sharedPData = data.b;
					return _Utils_Tuple2(
						detailHeader.header,
						A2($author$project$Traveller$AnalysisDetail$viewPlanetoidAnalysisDetail, timeChars, sharedPData));
				case 'AnalyisDetailGasGiant':
					var detailHeader = data.a;
					var sharedGGData = data.b;
					return _Utils_Tuple2(
						detailHeader.header,
						A2($author$project$Traveller$AnalysisDetail$viewGasGiantAnalysisDetail, timeChars, sharedGGData));
				case 'AnalyisDetailPlanetoidBelt':
					var detailHeader = data.a;
					var sharePBData = data.b;
					return _Utils_Tuple2(
						detailHeader.header,
						A2($author$project$Traveller$AnalysisDetail$viewPlanetoidBeltAnalysisDetail, timeChars, sharePBData));
				default:
					return _Utils_Tuple2(
						'TODO: Star',
						$mdgriffith$elm_ui$Element$text('Star not yet implemented'));
			}
		}();
		var header = _v0.a;
		var content = _v0.b;
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
					$mdgriffith$elm_ui$Element$centerX,
					$mdgriffith$elm_ui$Element$centerY,
					$mdgriffith$elm_ui$Element$Background$color(
					A4($mdgriffith$elm_ui$Element$rgba, 0.3, 0.3, 0.3, 0.95)),
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(750)),
					$mdgriffith$elm_ui$Element$padding(4),
					$mdgriffith$elm_ui$Element$Border$rounded(3),
					$mdgriffith$elm_ui$Element$Border$shadow(
					{
						blur: 4,
						color: A4($mdgriffith$elm_ui$Element$rgba, 0.1, 0.1, 0.1, 1 / 8),
						offset: _Utils_Tuple2(1, 1),
						size: 2
					})
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$row,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
						]),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$size(24),
									$mdgriffith$elm_ui$Element$paddingEach(
									_Utils_update(
										$author$project$Traveller$UI$zeroEach,
										{bottom: 15}))
								]),
							$mdgriffith$elm_ui$Element$text(header)),
							A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$paddingEach(
									{bottom: 10, left: 10, right: 10, top: 0}),
									$mdgriffith$elm_ui$Element$pointer,
									$mdgriffith$elm_ui$Element$mouseOver(
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$Font$color(
											A3($mdgriffith$elm_ui$Element$rgb, 0.8, 0.8, 0.8))
										])),
									$mdgriffith$elm_ui$Element$Font$size(16),
									$mdgriffith$elm_ui$Element$alignRight,
									$mdgriffith$elm_ui$Element$alignTop,
									$mdgriffith$elm_ui$Element$Events$onClick(closeMsg)
								]),
							$mdgriffith$elm_ui$Element$text('X'))
						])),
					content
				]));
	});
var $mdgriffith$elm_ui$Element$fromRgb = function (clr) {
	return A4($mdgriffith$elm_ui$Internal$Model$Rgba, clr.red, clr.green, clr.blue, clr.alpha);
};
var $author$project$Traveller$StellarObjectView$convertColor = function (color) {
	return $mdgriffith$elm_ui$Element$fromRgb(
		$avh4$elm_color$Color$toRgba(color));
};
var $mdgriffith$elm_ui$Element$Lazy$apply1 = F2(
	function (fn, a) {
		return $mdgriffith$elm_ui$Element$Lazy$embed(
			fn(a));
	});
var $mdgriffith$elm_ui$Element$Lazy$lazy = F2(
	function (fn, a) {
		return $mdgriffith$elm_ui$Internal$Model$Unstyled(
			A3($elm$virtual_dom$VirtualDom$lazy3, $mdgriffith$elm_ui$Element$Lazy$apply1, fn, a));
	});
var $mdgriffith$elm_ui$Element$Lazy$apply4 = F5(
	function (fn, a, b, c, d) {
		return $mdgriffith$elm_ui$Element$Lazy$embed(
			A4(fn, a, b, c, d));
	});
var $elm$virtual_dom$VirtualDom$lazy6 = _VirtualDom_lazy6;
var $mdgriffith$elm_ui$Element$Lazy$lazy4 = F5(
	function (fn, a, b, c, d) {
		return $mdgriffith$elm_ui$Internal$Model$Unstyled(
			A6($elm$virtual_dom$VirtualDom$lazy6, $mdgriffith$elm_ui$Element$Lazy$apply4, fn, a, b, c, d));
	});
var $avh4$elm_color$Color$hsla = F4(
	function (hue, sat, light, alpha) {
		var _v0 = _Utils_Tuple3(hue, sat, light);
		var h = _v0.a;
		var s = _v0.b;
		var l = _v0.c;
		var m2 = (l <= 0.5) ? (l * (s + 1)) : ((l + s) - (l * s));
		var m1 = (l * 2) - m2;
		var hueToRgb = function (h__) {
			var h_ = (h__ < 0) ? (h__ + 1) : ((h__ > 1) ? (h__ - 1) : h__);
			return ((h_ * 6) < 1) ? (m1 + (((m2 - m1) * h_) * 6)) : (((h_ * 2) < 1) ? m2 : (((h_ * 3) < 2) ? (m1 + (((m2 - m1) * ((2 / 3) - h_)) * 6)) : m1));
		};
		var b = hueToRgb(h - (1 / 3));
		var g = hueToRgb(h);
		var r = hueToRgb(h + (1 / 3));
		return A4($avh4$elm_color$Color$RgbaSpace, r, g, b, alpha);
	});
var $noahzgordon$elm_color_extra$Color$Manipulate$limit = A2($elm$core$Basics$clamp, 0, 1);
var $avh4$elm_color$Color$toHsla = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	var minColor = A2(
		$elm$core$Basics$min,
		r,
		A2($elm$core$Basics$min, g, b));
	var maxColor = A2(
		$elm$core$Basics$max,
		r,
		A2($elm$core$Basics$max, g, b));
	var l = (minColor + maxColor) / 2;
	var s = _Utils_eq(minColor, maxColor) ? 0 : ((l < 0.5) ? ((maxColor - minColor) / (maxColor + minColor)) : ((maxColor - minColor) / ((2 - maxColor) - minColor)));
	var h1 = _Utils_eq(maxColor, r) ? ((g - b) / (maxColor - minColor)) : (_Utils_eq(maxColor, g) ? (2 + ((b - r) / (maxColor - minColor))) : (4 + ((r - g) / (maxColor - minColor))));
	var h2 = h1 * (1 / 6);
	var h3 = $elm$core$Basics$isNaN(h2) ? 0 : ((h2 < 0) ? (h2 + 1) : h2);
	return {alpha: a, hue: h3, lightness: l, saturation: s};
};
var $noahzgordon$elm_color_extra$Color$Manipulate$darken = F2(
	function (offset, cl) {
		var _v0 = $avh4$elm_color$Color$toHsla(cl);
		var hue = _v0.hue;
		var saturation = _v0.saturation;
		var lightness = _v0.lightness;
		var alpha = _v0.alpha;
		return A4(
			$avh4$elm_color$Color$hsla,
			hue,
			saturation,
			$noahzgordon$elm_color_extra$Color$Manipulate$limit(lightness - offset),
			alpha);
	});
var $noahzgordon$elm_color_extra$Color$Manipulate$lighten = F2(
	function (offset, cl) {
		return A2($noahzgordon$elm_color_extra$Color$Manipulate$darken, -offset, cl);
	});
var $elm$html$Html$i = _VirtualDom_node('i');
var $author$project$Traveller$Sidebar$renderFAIcon = F2(
	function (icon, size) {
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(size)),
					$mdgriffith$elm_ui$Element$height(
					$mdgriffith$elm_ui$Element$px(size))
				]),
			$mdgriffith$elm_ui$Element$html(
				A2(
					$elm$html$Html$i,
					_List_fromArray(
						[
							A2(
							$elm$html$Html$Attributes$style,
							'font-size',
							$elm$core$String$fromInt(size) + 'px'),
							$elm$html$Html$Attributes$class(icon)
						]),
					_List_Nil)));
	});
var $author$project$Traveller$HexAddress$toSectorKey = function (_v0) {
	var sectorX = _v0.sectorX;
	var sectorY = _v0.sectorY;
	return $elm$core$String$fromInt(sectorX) + ('.' + $elm$core$String$fromInt(sectorY));
};
var $author$project$Traveller$Sidebar$universalHexLabel = F2(
	function (sectors, hexAddress) {
		var _v0 = A2(
			$elm$core$Dict$get,
			$author$project$Traveller$HexAddress$toSectorKey(
				$author$project$Traveller$HexAddress$toSectorAddress(hexAddress)),
			sectors);
		if (_v0.$ === 'Nothing') {
			return ' ';
		} else {
			var sector = _v0.a;
			return sector.name + (' ' + $author$project$Traveller$HexAddress$hexLabel(hexAddress));
		}
	});
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $mdgriffith$elm_ui$Internal$Model$Bottom = {$: 'Bottom'};
var $mdgriffith$elm_ui$Element$alignBottom = $mdgriffith$elm_ui$Internal$Model$AlignY($mdgriffith$elm_ui$Internal$Model$Bottom);
var $elm$core$Debug$toString = _Debug_toString;
var $author$project$Traveller$Sidebar$viewSidebarFooter = function (selectedHex) {
	var _v0 = A2($elm$core$Debug$log, 'footer', 123);
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$padding(10),
				$mdgriffith$elm_ui$Element$alignBottom,
				$mdgriffith$elm_ui$Element$centerX,
				$mdgriffith$elm_ui$Element$Font$size(10),
				$author$project$Traveller$UI$uiDeepnightColorFontColour
			]),
		function () {
			if (selectedHex.$ === 'Just') {
				var viewingAddress = selectedHex.a;
				return $mdgriffith$elm_ui$Element$text(
					$elm$core$Debug$toString(viewingAddress));
			} else {
				return $mdgriffith$elm_ui$Element$text('Deepnight Corporation LLC');
			}
		}());
};
var $author$project$Traveller$TravelCalculations$calcDistance2F = F2(
	function (p1, p2) {
		var deltaY = p1.y - p2.y;
		var deltaX = p1.x - p2.x;
		var distanceSquared = (deltaX * deltaX) + (deltaY * deltaY);
		var distance = $elm$core$Basics$sqrt(distanceSquared);
		return distance;
	});
var $mdgriffith$elm_ui$Internal$Flag$fontAlignment = $mdgriffith$elm_ui$Internal$Flag$flag(12);
var $mdgriffith$elm_ui$Element$Font$alignLeft = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$fontAlignment, $mdgriffith$elm_ui$Internal$Style$classes.textLeft);
var $mdgriffith$elm_ui$Internal$Model$Behind = {$: 'Behind'};
var $mdgriffith$elm_ui$Element$behindContent = function (element) {
	return A2($mdgriffith$elm_ui$Element$createNearby, $mdgriffith$elm_ui$Internal$Model$Behind, element);
};
var $author$project$Traveller$StellarObject$getInnerStarData = function (_v0) {
	var starDataConfig = _v0.a;
	return starDataConfig;
};
var $mdgriffith$elm_ui$Internal$Flag$bgGradient = $mdgriffith$elm_ui$Internal$Flag$flag(10);
var $mdgriffith$elm_ui$Element$Background$gradient = function (_v0) {
	var angle = _v0.angle;
	var steps = _v0.steps;
	if (!steps.b) {
		return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
	} else {
		if (!steps.b.b) {
			var clr = steps.a;
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$bgColor,
				A3(
					$mdgriffith$elm_ui$Internal$Model$Colored,
					'bg-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(clr),
					'background-color',
					clr));
		} else {
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$bgGradient,
				A3(
					$mdgriffith$elm_ui$Internal$Model$Single,
					'bg-grad-' + A2(
						$elm$core$String$join,
						'-',
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$floatClass(angle),
							A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$formatColorClass, steps))),
					'background-image',
					'linear-gradient(' + (A2(
						$elm$core$String$join,
						', ',
						A2(
							$elm$core$List$cons,
							$elm$core$String$fromFloat(angle) + 'rad',
							A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$formatColor, steps))) + ')')));
		}
	}
};
var $author$project$Traveller$StellarObject$isBrownDwarf = function (theStar) {
	return A2(
		$elm$core$List$any,
		function (a) {
			return _Utils_eq(a, theStar.stellarType);
		},
		_List_fromArray(
			['D', 'Y', 'T', 'L']));
};
var $noahzgordon$elm_color_extra$Color$Manipulate$saturate = F2(
	function (offset, cl) {
		var _v0 = $avh4$elm_color$Color$toHsla(cl);
		var hue = _v0.hue;
		var saturation = _v0.saturation;
		var lightness = _v0.lightness;
		var alpha = _v0.alpha;
		return A4(
			$avh4$elm_color$Color$hsla,
			hue,
			$noahzgordon$elm_color_extra$Color$Manipulate$limit(saturation + offset),
			lightness,
			alpha);
	});
var $noahzgordon$elm_color_extra$Color$Manipulate$desaturate = F2(
	function (offset, cl) {
		return A2($noahzgordon$elm_color_extra$Color$Manipulate$saturate, -offset, cl);
	});
var $author$project$Traveller$UI$jumpShadowTextColor = $author$project$Traveller$UI$colorToElementColor(
	A2(
		$noahzgordon$elm_color_extra$Color$Manipulate$darken,
		0.85,
		A2($noahzgordon$elm_color_extra$Color$Manipulate$desaturate, 0.85, $author$project$Traveller$UI$textColor)));
var $author$project$Traveller$StellarObjectView$calcNestedOffset = function (newNestingLevel) {
	return newNestingLevel * 5;
};
var $author$project$Traveller$StellarObjectView$renderImage = F2(
	function (uwp, maybeTemp) {
		var hydrographics = ($elm$core$String$length(uwp) === 9) ? A3($elm$core$String$slice, 3, 4, uwp) : '';
		var gasGiantUwps = _List_fromArray(
			['GS', 'GM', 'GL']);
		var atmosphere = ($elm$core$String$length(uwp) === 9) ? A3($elm$core$String$slice, 2, 3, uwp) : '';
		var imageUrl = A2($elm$core$List$member, uwp, gasGiantUwps) ? '/images/gasgiant-small.png' : (((atmosphere === 'B') || (atmosphere === 'C')) ? '/images/corrosivehellworld-small.png' : ((hydrographics === 'A') ? '/images/waterworld-small.png' : ((hydrographics === '0') ? '/images/desertworld-small.png' : (((atmosphere === '1') || ((atmosphere === '2') || (atmosphere === '3'))) ? '/images/traceworld-small.png' : '/images/moon-small.png'))));
		return A2(
			$mdgriffith$elm_ui$Element$image,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(18)),
					$mdgriffith$elm_ui$Element$height(
					$mdgriffith$elm_ui$Element$px(18))
				]),
			{description: '', src: imageUrl});
	});
var $lattyware$elm_fontawesome$FontAwesome$IconDef = F4(
	function (prefix, name, size, paths) {
		return {name: name, paths: paths, prefix: prefix, size: size};
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$Definitions$arrowUpFromBracket = A4(
	$lattyware$elm_fontawesome$FontAwesome$IconDef,
	'fas',
	'arrow-up-from-bracket',
	_Utils_Tuple2(448, 512),
	_Utils_Tuple2('M246.6 9.4c-12.5-12.5-32.8-12.5-45.3 0l-128 128c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L192 109.3 192 320c0 17.7 14.3 32 32 32s32-14.3 32-32l0-210.7 73.4 73.4c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3l-128-128zM64 352c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 64c0 53 43 96 96 96l256 0c53 0 96-43 96-96l0-64c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 64c0 17.7-14.3 32-32 32L96 448c-17.7 0-32-14.3-32-32l0-64z', $elm$core$Maybe$Nothing));
var $lattyware$elm_fontawesome$FontAwesome$Internal$Icon = function (a) {
	return {$: 'Icon', a: a};
};
var $lattyware$elm_fontawesome$FontAwesome$present = function (icon) {
	return $lattyware$elm_fontawesome$FontAwesome$Internal$Icon(
		{attributes: _List_Nil, icon: icon, id: $elm$core$Maybe$Nothing, outer: $elm$core$Maybe$Nothing, role: 'img', title: $elm$core$Maybe$Nothing, transforms: _List_Nil});
};
var $lattyware$elm_fontawesome$FontAwesome$Solid$arrowUpFromBracket = $lattyware$elm_fontawesome$FontAwesome$present($lattyware$elm_fontawesome$FontAwesome$Solid$Definitions$arrowUpFromBracket);
var $author$project$Traveller$StellarObjectView$iconSizing = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$height(
		$mdgriffith$elm_ui$Element$px(16)),
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(16))
	]);
var $elm$html$Html$Attributes$map = $elm$virtual_dom$VirtualDom$mapAttribute;
var $elm$svg$Svg$title = $elm$svg$Svg$trustedNode('title');
var $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensions = function (_v1) {
	var icon = _v1.a.icon;
	var outer = _v1.a.outer;
	return A2(
		$elm$core$Maybe$withDefault,
		icon.size,
		A2($elm$core$Maybe$map, $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensionsInternal, outer));
};
var $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensionsInternal = function (_v0) {
	var icon = _v0.a.icon;
	var outer = _v0.a.outer;
	return A2(
		$elm$core$Maybe$withDefault,
		icon.size,
		A2($elm$core$Maybe$map, $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensions, outer));
};
var $elm$svg$Svg$defs = $elm$svg$Svg$trustedNode('defs');
var $lattyware$elm_fontawesome$FontAwesome$Svg$fill = _List_fromArray(
	[
		$elm$svg$Svg$Attributes$x('0'),
		$elm$svg$Svg$Attributes$y('0'),
		$elm$svg$Svg$Attributes$width('100%'),
		$elm$svg$Svg$Attributes$height('100%')
	]);
var $elm$svg$Svg$mask = $elm$svg$Svg$trustedNode('mask');
var $elm$svg$Svg$Attributes$mask = _VirtualDom_attribute('mask');
var $elm$svg$Svg$Attributes$maskContentUnits = _VirtualDom_attribute('maskContentUnits');
var $elm$svg$Svg$Attributes$maskUnits = _VirtualDom_attribute('maskUnits');
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add = F2(
	function (transform, combined) {
		switch (transform.$) {
			case 'Scale':
				var by = transform.a;
				return _Utils_update(
					combined,
					{size: combined.size + by});
			case 'Reposition':
				var axis = transform.a;
				var by = transform.b;
				var _v1 = function () {
					if (axis.$ === 'Vertical') {
						return _Utils_Tuple2(0, by);
					} else {
						return _Utils_Tuple2(by, 0);
					}
				}();
				var x = _v1.a;
				var y = _v1.b;
				return _Utils_update(
					combined,
					{x: combined.x + x, y: combined.y + y});
			case 'Rotate':
				var rotation = transform.a;
				return _Utils_update(
					combined,
					{rotate: combined.rotate + rotation});
			default:
				var axis = transform.a;
				if (axis.$ === 'Vertical') {
					return _Utils_update(
						combined,
						{flipY: !combined.flipY});
				} else {
					return _Utils_update(
						combined,
						{flipX: !combined.flipX});
				}
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize = 16;
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform = {flipX: false, flipY: false, rotate: 0, size: $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize, x: 0, y: 0};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine = function (transforms) {
	return A3($elm$core$List$foldl, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform, transforms);
};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform = function (transforms) {
	var combined = $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine(transforms);
	return _Utils_eq(combined, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(combined);
};
var $elm$svg$Svg$rect = $elm$svg$Svg$trustedNode('rect');
var $elm$svg$Svg$Attributes$transform = _VirtualDom_attribute('transform');
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg = F3(
	function (containerWidth, iconWidth, transform) {
		var path = 'translate(' + ($elm$core$String$fromFloat((iconWidth / 2) * (-1)) + ' -256)');
		var outer = 'translate(' + ($elm$core$String$fromFloat(containerWidth / 2) + ' 256)');
		var innerTranslate = 'translate(' + ($elm$core$String$fromFloat(transform.x * 32) + (',' + ($elm$core$String$fromFloat(transform.y * 32) + ') ')));
		var innerRotate = 'rotate(' + ($elm$core$String$fromFloat(transform.rotate) + ' 0 0)');
		var flipY = transform.flipY ? (-1) : 1;
		var scaleY = (transform.size / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipY;
		var flipX = transform.flipX ? (-1) : 1;
		var scaleX = (transform.size / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipX;
		var innerScale = 'scale(' + ($elm$core$String$fromFloat(scaleX) + (', ' + ($elm$core$String$fromFloat(scaleY) + ') ')));
		return {
			inner: $elm$svg$Svg$Attributes$transform(
				_Utils_ap(
					innerTranslate,
					_Utils_ap(innerScale, innerRotate))),
			outer: $elm$svg$Svg$Attributes$transform(outer),
			path: $elm$svg$Svg$Attributes$transform(path)
		};
	});
var $elm$svg$Svg$Attributes$d = _VirtualDom_attribute('d');
var $elm$svg$Svg$path = $elm$svg$Svg$trustedNode('path');
var $lattyware$elm_fontawesome$FontAwesome$Svg$viewPath = F2(
	function (attrs, d) {
		return A2(
			$elm$svg$Svg$path,
			A2(
				$elm$core$List$cons,
				$elm$svg$Svg$Attributes$d(d),
				attrs),
			_List_Nil);
	});
var $lattyware$elm_fontawesome$FontAwesome$Svg$viewPaths = F2(
	function (attrs, _v0) {
		var paths = _v0.paths;
		if (paths.b.$ === 'Nothing') {
			var only = paths.a;
			var _v2 = paths.b;
			return A2($lattyware$elm_fontawesome$FontAwesome$Svg$viewPath, attrs, only);
		} else {
			var secondary = paths.a;
			var primary = paths.b.a;
			return A2(
				$elm$svg$Svg$g,
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$class('fa-group')
					]),
				_List_fromArray(
					[
						A2(
						$lattyware$elm_fontawesome$FontAwesome$Svg$viewPath,
						A2(
							$elm$core$List$cons,
							$elm$svg$Svg$Attributes$class('fa-secondary'),
							attrs),
						secondary),
						A2(
						$lattyware$elm_fontawesome$FontAwesome$Svg$viewPath,
						A2(
							$elm$core$List$cons,
							$elm$svg$Svg$Attributes$class('fa-primary'),
							attrs),
						primary)
					]));
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Svg$viewWithTransform = F3(
	function (color, _v0, icon) {
		var outer = _v0.outer;
		var inner = _v0.inner;
		var path = _v0.path;
		return A2(
			$elm$svg$Svg$g,
			_List_fromArray(
				[outer]),
			_List_fromArray(
				[
					A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[inner]),
					_List_fromArray(
						[
							A2(
							$lattyware$elm_fontawesome$FontAwesome$Svg$viewPaths,
							_List_fromArray(
								[
									$elm$svg$Svg$Attributes$fill(color),
									path
								]),
							icon)
						]))
				]));
	});
var $lattyware$elm_fontawesome$FontAwesome$Svg$viewInColor = F2(
	function (color, fullIcon) {
		var icon = fullIcon.a.icon;
		var transforms = fullIcon.a.transforms;
		var id = fullIcon.a.id;
		var outer = fullIcon.a.outer;
		var combinedTransforms = $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform(transforms);
		var _v0 = icon.size;
		var width = _v0.a;
		var _v1 = $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensions(fullIcon);
		var topLevelWidth = _v1.a;
		if (combinedTransforms.$ === 'Just') {
			var meaningfulTransform = combinedTransforms.a;
			var svgTransform = A3($lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg, topLevelWidth, width, meaningfulTransform);
			if (outer.$ === 'Just') {
				var outerIcon = outer.a;
				return A4($lattyware$elm_fontawesome$FontAwesome$Svg$viewMaskedWithTransform, color, svgTransform, icon, outerIcon);
			} else {
				return A3($lattyware$elm_fontawesome$FontAwesome$Svg$viewWithTransform, color, svgTransform, icon);
			}
		} else {
			return A2(
				$lattyware$elm_fontawesome$FontAwesome$Svg$viewPaths,
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$fill(color)
					]),
				icon);
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Svg$viewMaskedWithTransform = F4(
	function (color, transforms, exclude, include) {
		var id = include.a.id;
		var alwaysId = A2($elm$core$Maybe$withDefault, '', id);
		var clipId = 'clip-' + alwaysId;
		var maskId = 'mask-' + alwaysId;
		var maskTag = A2(
			$elm$svg$Svg$mask,
			A2(
				$elm$core$List$cons,
				$elm$svg$Svg$Attributes$id(maskId),
				A2(
					$elm$core$List$cons,
					$elm$svg$Svg$Attributes$maskUnits('userSpaceOnUse'),
					A2(
						$elm$core$List$cons,
						$elm$svg$Svg$Attributes$maskContentUnits('userSpaceOnUse'),
						$lattyware$elm_fontawesome$FontAwesome$Svg$fill))),
			_List_fromArray(
				[
					A2($lattyware$elm_fontawesome$FontAwesome$Svg$viewInColor, 'white', include),
					A3($lattyware$elm_fontawesome$FontAwesome$Svg$viewWithTransform, 'black', transforms, exclude)
				]));
		var defs = A2(
			$elm$svg$Svg$defs,
			_List_Nil,
			_List_fromArray(
				[maskTag]));
		var rect = A2(
			$elm$svg$Svg$rect,
			A2(
				$elm$core$List$cons,
				$elm$svg$Svg$Attributes$fill(color),
				A2(
					$elm$core$List$cons,
					$elm$svg$Svg$Attributes$mask('url(#' + (maskId + ')')),
					$lattyware$elm_fontawesome$FontAwesome$Svg$fill)),
			_List_Nil);
		return A2(
			$elm$svg$Svg$g,
			_List_Nil,
			_List_fromArray(
				[defs, rect]));
	});
var $lattyware$elm_fontawesome$FontAwesome$Svg$view = $lattyware$elm_fontawesome$FontAwesome$Svg$viewInColor('currentColor');
var $lattyware$elm_fontawesome$FontAwesome$internalView = F2(
	function (fullIcon, extraAttributes) {
		var icon = fullIcon.a.icon;
		var transforms = fullIcon.a.transforms;
		var role = fullIcon.a.role;
		var id = fullIcon.a.id;
		var title = fullIcon.a.title;
		var outer = fullIcon.a.outer;
		var attributes = fullIcon.a.attributes;
		var contents = $lattyware$elm_fontawesome$FontAwesome$Svg$view(fullIcon);
		var _v0 = function () {
			if (title.$ === 'Just') {
				var givenTitle = title.a;
				var titleId = A2($elm$core$Maybe$withDefault, '', id) + '-title';
				return _Utils_Tuple2(
					A2($elm$html$Html$Attributes$attribute, 'aria-labelledby', titleId),
					_List_fromArray(
						[
							A2(
							$elm$svg$Svg$title,
							_List_fromArray(
								[
									$elm$svg$Svg$Attributes$id(titleId)
								]),
							_List_fromArray(
								[
									$elm$svg$Svg$text(givenTitle)
								])),
							contents
						]));
			} else {
				return _Utils_Tuple2(
					A2($elm$html$Html$Attributes$attribute, 'aria-hidden', 'true'),
					_List_fromArray(
						[contents]));
			}
		}();
		var semantics = _v0.a;
		var potentiallyTitledContents = _v0.b;
		var _v2 = $lattyware$elm_fontawesome$FontAwesome$Internal$topLevelDimensions(fullIcon);
		var width = _v2.a;
		var height = _v2.b;
		var aspectRatio = $elm$core$Basics$ceiling((width / height) * 16);
		var classes = _List_fromArray(
			[
				'svg-inline--fa',
				'fa-' + icon.name,
				'fa-w-' + $elm$core$String$fromInt(aspectRatio)
			]);
		return A2(
			$elm$svg$Svg$svg,
			$elm$core$List$concat(
				_List_fromArray(
					[
						_List_fromArray(
						[
							A2($elm$html$Html$Attributes$attribute, 'role', role),
							A2($elm$html$Html$Attributes$attribute, 'xmlns', 'http://www.w3.org/2000/svg'),
							$elm$svg$Svg$Attributes$viewBox(
							'0 0 ' + ($elm$core$String$fromInt(width) + (' ' + $elm$core$String$fromInt(height)))),
							semantics
						]),
						A2($elm$core$List$map, $elm$svg$Svg$Attributes$class, classes),
						A2(
						$elm$core$List$map,
						$elm$html$Html$Attributes$map($elm$core$Basics$never),
						attributes),
						extraAttributes
					])),
			potentiallyTitledContents);
	});
var $lattyware$elm_fontawesome$FontAwesome$view = function (presentation) {
	return A2($lattyware$elm_fontawesome$FontAwesome$internalView, presentation, _List_Nil);
};
var $author$project$Traveller$StellarObjectView$renderIcon = function (icon) {
	var iconSpacing = _Utils_update(
		$author$project$Traveller$UI$zeroEach,
		{right: 4});
	return A2(
		$mdgriffith$elm_ui$Element$el,
		A2(
			$elm$core$List$cons,
			$mdgriffith$elm_ui$Element$paddingEach(iconSpacing),
			$author$project$Traveller$StellarObjectView$iconSizing),
		$mdgriffith$elm_ui$Element$html(
			$lattyware$elm_fontawesome$FontAwesome$view(icon)));
};
var $author$project$Traveller$UI$safeJumpStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(62)),
		$mdgriffith$elm_ui$Element$Font$size(12)
	]);
var $myrho$elm_round$Round$ceiling = $myrho$elm_round$Round$roundFun(
	F2(
		function (signed, str) {
			var _v0 = $elm$core$String$uncons(str);
			if (_v0.$ === 'Nothing') {
				return false;
			} else {
				if ('0' === _v0.a.a.valueOf()) {
					var _v1 = _v0.a;
					var rest = _v1.b;
					return (!signed) && A2(
						$elm$core$List$any,
						$elm$core$Basics$neq(
							_Utils_chr('0')),
						$elm$core$String$toList(rest));
				} else {
					return !signed;
				}
			}
		}));
var $myrho$elm_round$Round$floor = $myrho$elm_round$Round$roundFun(
	F2(
		function (signed, str) {
			var _v0 = $elm$core$String$uncons(str);
			if (_v0.$ === 'Nothing') {
				return false;
			} else {
				if ('0' === _v0.a.a.valueOf()) {
					var _v1 = _v0.a;
					var rest = _v1.b;
					return signed && A2(
						$elm$core$List$any,
						$elm$core$Basics$neq(
							_Utils_chr('0')),
						$elm$core$String$toList(rest));
				} else {
					return signed;
				}
			}
		}));
var $author$project$Traveller$TravelCalculations$secondsToDaysWatches = function (secs) {
	var watches = $elm$core$Basics$ceiling(secs / ((60 * 60) * 8));
	var days = $elm$core$Basics$floor(watches / 3);
	var watches_ = watches - (days * 3);
	return A2($myrho$elm_round$Round$floor, 0, days) + ('d ' + (A2($myrho$elm_round$Round$ceiling, 0, watches_) + 'w'));
};
var $author$project$Traveller$StellarObjectView$renderJumpTime = F2(
	function (maxJumpTime, time) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			$author$project$Traveller$UI$safeJumpStyle,
			_List_fromArray(
				[
					$author$project$Traveller$StellarObjectView$renderIcon($lattyware$elm_fontawesome$FontAwesome$Solid$arrowUpFromBracket),
					$mdgriffith$elm_ui$Element$text(
					function () {
						if (maxJumpTime.$ === 'Just') {
							var maxTime = maxJumpTime.a;
							return $author$project$Traveller$TravelCalculations$secondsToDaysWatches(maxTime);
						} else {
							return time;
						}
					}())
				]));
	});
var $author$project$Traveller$UI$orbitStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(45)),
		$mdgriffith$elm_ui$Element$alignRight
	]);
var $author$project$Traveller$StellarObjectView$renderOrbit = function (au) {
	var zoneImage = '';
	var roundedAU = (au < 1) ? A2($myrho$elm_round$Round$round, 2, au) : A2($myrho$elm_round$Round$round, 1, au);
	return A2(
		$mdgriffith$elm_ui$Element$el,
		$author$project$Traveller$UI$orbitStyle,
		$author$project$Traveller$UI$monospaceText(
			_Utils_ap(roundedAU, zoneImage)));
};
var $author$project$Traveller$UI$sequenceStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(60))
	]);
var $author$project$Traveller$StellarObjectView$renderOrbitSequence = function (sequence) {
	return A2(
		$mdgriffith$elm_ui$Element$el,
		$author$project$Traveller$UI$sequenceStyle,
		$author$project$Traveller$UI$monospaceText(sequence));
};
var $author$project$Traveller$UI$descriptionStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(84))
	]);
var $author$project$Traveller$StellarObjectView$renderIconRaw = function (icon) {
	var iconSpacing = _Utils_update(
		$author$project$Traveller$UI$zeroEach,
		{right: 4});
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$paddingEach(iconSpacing),
				$mdgriffith$elm_ui$Element$height(
				$mdgriffith$elm_ui$Element$px(10)),
				$mdgriffith$elm_ui$Element$width(
				$mdgriffith$elm_ui$Element$px(10))
			]),
		$mdgriffith$elm_ui$Element$html(
			A2(
				$elm$html$Html$i,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class(icon)
					]),
				_List_Nil)));
};
var $author$project$Traveller$StellarObjectView$renderSODescription = F3(
	function (onClick, description, orbitSequence) {
		return A2(
			$mdgriffith$elm_ui$Element$el,
			$author$project$Traveller$UI$descriptionStyle,
			A2(
				$mdgriffith$elm_ui$Element$row,
				_List_Nil,
				_List_fromArray(
					[
						$author$project$Traveller$UI$monospaceText(description),
						A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$Font$size(10),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$paddingEach(
								_Utils_update(
									$author$project$Traveller$UI$zeroEach,
									{left: 4, top: 2})),
								$mdgriffith$elm_ui$Element$pointer,
								$mdgriffith$elm_ui$Element$mouseOver(
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$color(
										A3($mdgriffith$elm_ui$Element$rgb, 1, 1, 1))
									])),
								$mdgriffith$elm_ui$Element$Events$onClick(onClick)
							]),
						$author$project$Traveller$StellarObjectView$renderIconRaw('fa-solid fa-scanner-touchscreen'))
					])));
	});
var $author$project$Traveller$UI$travelStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$width(
		$mdgriffith$elm_ui$Element$px(60))
	]);
var $author$project$Traveller$TravelCalculations$travelTimeInSeconds = F2(
	function (kms, mdrive) {
		return 2 * $elm$core$Basics$sqrt((kms * 1000) / (mdrive * 9.8));
	});
var $author$project$Traveller$TravelCalculations$travelTime = F3(
	function (kms, mdrive, useHours) {
		var rawSeconds = A2($author$project$Traveller$TravelCalculations$travelTimeInSeconds, kms, mdrive);
		if (useHours) {
			var rawMinutes = $elm$core$Basics$ceiling(rawSeconds / 60);
			var hours = $elm$core$Basics$floor(rawMinutes / 60);
			var minutes = rawMinutes - (hours * 60);
			return (hours > 0) ? (A2($myrho$elm_round$Round$floor, 0, hours) + ('h ' + (A2($myrho$elm_round$Round$ceiling, 0, minutes) + 'm'))) : (A2($myrho$elm_round$Round$ceiling, 0, minutes) + 'm');
		} else {
			return $author$project$Traveller$TravelCalculations$secondsToDaysWatches(rawSeconds);
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$Definitions$upDown = A4(
	$lattyware$elm_fontawesome$FontAwesome$IconDef,
	'fas',
	'up-down',
	_Utils_Tuple2(256, 512),
	_Utils_Tuple2('M145.6 7.7C141 2.8 134.7 0 128 0s-13 2.8-17.6 7.7l-104 112c-6.5 7-8.2 17.2-4.4 25.9S14.5 160 24 160l56 0 0 192-56 0c-9.5 0-18.2 5.7-22 14.4s-2.1 18.9 4.4 25.9l104 112c4.5 4.9 10.9 7.7 17.6 7.7s13-2.8 17.6-7.7l104-112c6.5-7 8.2-17.2 4.4-25.9s-12.5-14.4-22-14.4l-56 0 0-192 56 0c9.5 0 18.2-5.7 22-14.4s2.1-18.9-4.4-25.9l-104-112z', $elm$core$Maybe$Nothing));
var $lattyware$elm_fontawesome$FontAwesome$Solid$upDown = $lattyware$elm_fontawesome$FontAwesome$present($lattyware$elm_fontawesome$FontAwesome$Solid$Definitions$upDown);
var $author$project$Traveller$StellarObjectView$renderTravelTime = F2(
	function (destination, origin) {
		var shipMDrive = 4;
		var travelTimeStr = function () {
			if (origin.$ === 'Just') {
				var obj = origin.a;
				if (!_Utils_eq(obj, destination)) {
					var objPosition = $author$project$Traveller$StellarObject$getStellarOrbit(obj).orbitPosition;
					var destPosition = $author$project$Traveller$StellarObject$getStellarOrbit(destination).orbitPosition;
					var dist = A2($author$project$Traveller$TravelCalculations$calcDistance2F, destPosition, objPosition);
					return A3($author$project$Traveller$TravelCalculations$travelTime, dist, shipMDrive, false);
				} else {
					return '';
				}
			} else {
				return '';
			}
		}();
		if (origin.$ === 'Just') {
			var obj = origin.a;
			return (!_Utils_eq(obj, destination)) ? A2(
				$mdgriffith$elm_ui$Element$el,
				$author$project$Traveller$UI$travelStyle,
				$author$project$Traveller$UI$monospaceText(travelTimeStr)) : A2(
				$mdgriffith$elm_ui$Element$row,
				$author$project$Traveller$UI$travelStyle,
				_List_fromArray(
					[
						$author$project$Traveller$StellarObjectView$renderIcon($lattyware$elm_fontawesome$FontAwesome$Solid$upDown)
					]));
		} else {
			return $author$project$Traveller$UI$monospaceText('');
		}
	});
var $author$project$Traveller$StellarObjectView$renderGasGiant = F6(
	function (msgs, newNestingLevel, gasGiantData, jumpShadowCheckers, selectedStellarObject, isReferee) {
		var stellarObject = $author$project$Traveller$StellarObject$GasGiant(gasGiantData);
		var orbit = $author$project$Traveller$StellarObjectView$renderOrbit(gasGiantData.au);
		var maxShadow = $elm$core$List$maximum(
			A2(
				$elm$core$List$filterMap,
				function (checker) {
					return checker(stellarObject);
				},
				jumpShadowCheckers));
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(8),
					$mdgriffith$elm_ui$Element$moveRight(
					$author$project$Traveller$StellarObjectView$calcNestedOffset(newNestingLevel)),
					$mdgriffith$elm_ui$Element$Font$size(14),
					$mdgriffith$elm_ui$Element$Events$onClick(
					msgs.onFocusInSidebar(stellarObject))
				]),
			_List_fromArray(
				[
					orbit,
					$author$project$Traveller$StellarObjectView$renderOrbitSequence(gasGiantData.orbitSequence),
					A3(
					$author$project$Traveller$StellarObjectView$renderSODescription,
					msgs.onViewDetail(stellarObject),
					gasGiantData.code,
					gasGiantData.orbitSequence),
					A2($author$project$Traveller$StellarObjectView$renderImage, gasGiantData.code, $elm$core$Maybe$Nothing),
					A2($author$project$Traveller$StellarObjectView$renderJumpTime, maxShadow, gasGiantData.safeJumpTime),
					A2($author$project$Traveller$StellarObjectView$renderTravelTime, stellarObject, selectedStellarObject)
				]));
	});
var $author$project$Traveller$StellarObjectView$renderPlanetoid = F6(
	function (msgs, newNestingLevel, planetoidData, jumpShadowCheckers, selectedStellarObject, isReferee) {
		var planet = $author$project$Traveller$StellarObject$Planetoid(planetoidData);
		var orbit = $author$project$Traveller$StellarObjectView$renderOrbit(planetoidData.au);
		var maxShadow = $elm$core$List$maximum(
			A2(
				$elm$core$List$filterMap,
				function (checker) {
					return checker(planet);
				},
				jumpShadowCheckers));
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(8),
					$mdgriffith$elm_ui$Element$moveRight(
					$author$project$Traveller$StellarObjectView$calcNestedOffset(newNestingLevel)),
					$mdgriffith$elm_ui$Element$Font$size(14),
					$mdgriffith$elm_ui$Element$Events$onClick(
					msgs.onFocusInSidebar(planet))
				]),
			_List_fromArray(
				[
					orbit,
					$author$project$Traveller$StellarObjectView$renderOrbitSequence(planetoidData.orbitSequence),
					A3(
					$author$project$Traveller$StellarObjectView$renderSODescription,
					msgs.onViewDetail(planet),
					planetoidData.uwp,
					planetoidData.orbitSequence),
					A2($author$project$Traveller$StellarObjectView$renderImage, planetoidData.uwp, planetoidData.meanTemperature),
					A2($author$project$Traveller$StellarObjectView$renderJumpTime, maxShadow, planetoidData.safeJumpTime),
					A2($author$project$Traveller$StellarObjectView$renderTravelTime, planet, selectedStellarObject)
				]));
	});
var $author$project$Traveller$StellarObjectView$renderPlanetoidBelt = F6(
	function (msgs, newNestingLevel, planetoidBeltData, jumpShadowCheckers, selectedStellarObject, isReferee) {
		var orbit = $author$project$Traveller$StellarObjectView$renderOrbit(planetoidBeltData.au);
		var belt = $author$project$Traveller$StellarObject$PlanetoidBelt(planetoidBeltData);
		var maxShadow = $elm$core$List$maximum(
			A2(
				$elm$core$List$filterMap,
				function (checker) {
					return checker(belt);
				},
				jumpShadowCheckers));
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(8),
					$mdgriffith$elm_ui$Element$moveRight(
					$author$project$Traveller$StellarObjectView$calcNestedOffset(newNestingLevel)),
					$mdgriffith$elm_ui$Element$Font$size(14),
					$mdgriffith$elm_ui$Element$Events$onClick(
					msgs.onFocusInSidebar(belt))
				]),
			_List_fromArray(
				[
					orbit,
					$author$project$Traveller$StellarObjectView$renderOrbitSequence(planetoidBeltData.orbitSequence),
					A3(
					$author$project$Traveller$StellarObjectView$renderSODescription,
					msgs.onViewDetail(belt),
					planetoidBeltData.uwp,
					planetoidBeltData.orbitSequence),
					A2($author$project$Traveller$StellarObjectView$renderImage, planetoidBeltData.uwp, $elm$core$Maybe$Nothing),
					A2($author$project$Traveller$StellarObjectView$renderJumpTime, maxShadow, planetoidBeltData.safeJumpTime),
					A2($author$project$Traveller$StellarObjectView$renderTravelTime, belt, selectedStellarObject)
				]));
	});
var $author$project$Traveller$StellarObjectView$renderRawOrbit = function (au) {
	var roundedAU = (au < 1) ? A2($myrho$elm_round$Round$round, 2, au) : A2($myrho$elm_round$Round$round, 1, au);
	return A2(
		$mdgriffith$elm_ui$Element$el,
		$author$project$Traveller$UI$orbitStyle,
		$author$project$Traveller$UI$monospaceText(roundedAU));
};
var $author$project$Traveller$StellarObjectView$renderTerrestrialPlanet = F6(
	function (msgs, newNestingLevel, terrestrialData, jumpShadowCheckers, selectedStellarObject, isReferee) {
		var planet = $author$project$Traveller$StellarObject$TerrestrialPlanet(terrestrialData);
		var orbit = $author$project$Traveller$StellarObjectView$renderOrbit(terrestrialData.au);
		var maxShadow = $elm$core$List$maximum(
			A2(
				$elm$core$List$filterMap,
				function (checker) {
					return checker(planet);
				},
				jumpShadowCheckers));
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(8),
					$mdgriffith$elm_ui$Element$moveRight(
					$author$project$Traveller$StellarObjectView$calcNestedOffset(newNestingLevel)),
					$mdgriffith$elm_ui$Element$Font$size(14),
					$mdgriffith$elm_ui$Element$Events$onClick(
					msgs.onFocusInSidebar(planet))
				]),
			_List_fromArray(
				[
					orbit,
					$author$project$Traveller$StellarObjectView$renderOrbitSequence(terrestrialData.orbitSequence),
					A3(
					$author$project$Traveller$StellarObjectView$renderSODescription,
					msgs.onViewDetail(planet),
					terrestrialData.uwp,
					terrestrialData.orbitSequence),
					A2($author$project$Traveller$StellarObjectView$renderImage, terrestrialData.uwp, terrestrialData.meanTemperature),
					A2($author$project$Traveller$StellarObjectView$renderJumpTime, maxShadow, terrestrialData.safeJumpTime),
					A2($author$project$Traveller$StellarObjectView$renderTravelTime, planet, selectedStellarObject)
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$formatTextShadow = function (shadow) {
	return A2(
		$elm$core$String$join,
		' ',
		_List_fromArray(
			[
				$elm$core$String$fromFloat(shadow.offset.a) + 'px',
				$elm$core$String$fromFloat(shadow.offset.b) + 'px',
				$elm$core$String$fromFloat(shadow.blur) + 'px',
				$mdgriffith$elm_ui$Internal$Model$formatColor(shadow.color)
			]));
};
var $mdgriffith$elm_ui$Internal$Model$textShadowClass = function (shadow) {
	return $elm$core$String$concat(
		_List_fromArray(
			[
				'txt',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.offset.a) + 'px',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.offset.b) + 'px',
				$mdgriffith$elm_ui$Internal$Model$floatClass(shadow.blur) + 'px',
				$mdgriffith$elm_ui$Internal$Model$formatColorClass(shadow.color)
			]));
};
var $mdgriffith$elm_ui$Internal$Flag$txtShadows = $mdgriffith$elm_ui$Internal$Flag$flag(18);
var $mdgriffith$elm_ui$Element$Font$shadow = function (shade) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$txtShadows,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Single,
			$mdgriffith$elm_ui$Internal$Model$textShadowClass(shade),
			'text-shadow',
			$mdgriffith$elm_ui$Internal$Model$formatTextShadow(shade)));
};
var $author$project$Traveller$UI$travellerRed = A3($mdgriffith$elm_ui$Element$rgb, 0.882, 0.024, 0);
var $author$project$Traveller$StellarObjectView$displayStarDetails = F7(
	function (msgs, surveyIndex, _v1, nestingLevel, jumpShadowCheckers, selectedStellarObject, isReferee) {
		var starData = _v1.a;
		var nextNestingLevel = nestingLevel + 1;
		var isKnown = function (obj) {
			switch (obj.$) {
				case 'GasGiant':
					return surveyIndex >= 5;
				case 'TerrestrialPlanet':
					return surveyIndex >= 6;
				case 'PlanetoidBelt':
					return surveyIndex >= 6;
				case 'Planetoid':
					return surveyIndex >= 6;
				default:
					var childStar = obj.a;
					return $author$project$Traveller$StellarObject$isBrownDwarf(
						$author$project$Traveller$StellarObject$getInnerStarData(childStar)) ? (surveyIndex >= 4) : (surveyIndex >= 3);
			}
		};
		var isDisplayable = function (obj) {
			if (obj.$ === 'Planetoid') {
				var pdata = obj.a;
				return (pdata.size !== 'S') && (pdata.size !== '0');
			} else {
				return true;
			}
		};
		var inJumpShadow = function (obj) {
			var _v4 = starData.jumpShadow;
			if (_v4.$ === 'Just') {
				var jumpShadow = _v4.a;
				return _Utils_cmp(
					jumpShadow,
					$author$project$Traveller$StellarObject$getStellarOrbit(obj).au) > -1;
			} else {
				return false;
			}
		};
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$Background$color(
					$author$project$Traveller$StellarObjectView$convertColor(
						A2(
							$noahzgordon$elm_color_extra$Color$Manipulate$darken,
							0.4,
							A4($avh4$elm_color$Color$rgba, 33 / 255.0, 37 / 255.0, 41 / 255.0, 0.15)))),
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
					$mdgriffith$elm_ui$Element$moveRight(nestingLevel * 5),
					$mdgriffith$elm_ui$Element$Border$rounded(10),
					$mdgriffith$elm_ui$Element$width(
					A2($mdgriffith$elm_ui$Element$minimum, 200, $mdgriffith$elm_ui$Element$fill)),
					$mdgriffith$elm_ui$Element$spacing(10),
					A2($mdgriffith$elm_ui$Element$paddingXY, 0, 5)
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$row,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Element$paddingXY, 4, 0),
							$mdgriffith$elm_ui$Element$Font$alignLeft,
							$mdgriffith$elm_ui$Element$alignLeft
						]),
					_List_fromArray(
						[
							((!starData.orbitPosition.x) && (!starData.orbitPosition.y)) ? $mdgriffith$elm_ui$Element$none : $author$project$Traveller$StellarObjectView$renderRawOrbit(starData.au),
							A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$alignLeft,
									$mdgriffith$elm_ui$Element$alignLeft,
									$mdgriffith$elm_ui$Element$Font$size(16),
									$mdgriffith$elm_ui$Element$Font$bold
								]),
							$mdgriffith$elm_ui$Element$text(
								starData.stellarType + (function () {
									var _v2 = starData.subtype;
									if (_v2.$ === 'Just') {
										var num = _v2.a;
										return $elm$core$String$fromInt(num);
									} else {
										return '';
									}
								}() + (' ' + starData.stellarClass))))
						])),
					A2(
					$elm$core$Maybe$withDefault,
					$mdgriffith$elm_ui$Element$none,
					A2(
						$elm$core$Maybe$map,
						function (compStarData) {
							return A7($author$project$Traveller$StellarObjectView$displayStarDetails, msgs, surveyIndex, compStarData, nextNestingLevel, jumpShadowCheckers, selectedStellarObject, isReferee);
						},
						starData.companion)),
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Element$paddingXY, 4, 0),
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
						]),
					function () {
						var red = A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
									$mdgriffith$elm_ui$Element$height(
									$mdgriffith$elm_ui$Element$px(4)),
									$mdgriffith$elm_ui$Element$centerY,
									$mdgriffith$elm_ui$Element$Border$rounded(2),
									$mdgriffith$elm_ui$Element$Background$gradient(
									{
										angle: $elm$core$Basics$pi / 2.0,
										steps: _List_fromArray(
											[
												$author$project$Traveller$UI$travellerRed,
												A4($mdgriffith$elm_ui$Element$rgba, 0, 0, 0, 0.25),
												$author$project$Traveller$UI$travellerRed
											])
									})
								]),
							$mdgriffith$elm_ui$Element$text(' '));
						return _List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_Nil,
								A2(
									$elm$core$List$map,
									function (so) {
										return A7($author$project$Traveller$StellarObjectView$renderStellarObject, msgs, surveyIndex, nextNestingLevel, so, jumpShadowCheckers, selectedStellarObject, isReferee);
									},
									A2(
										$elm$core$List$filter,
										isKnown,
										A2(
											$elm$core$List$filter,
											inJumpShadow,
											A2($elm$core$List$filter, isDisplayable, starData.stellarObjects))))),
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$size(14),
										$mdgriffith$elm_ui$Element$Font$shadow(
										{
											blur: 1,
											color: $author$project$Traveller$UI$jumpShadowTextColor,
											offset: _Utils_Tuple2(0.5, 0.5)
										}),
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$behindContent(red)
									]),
								_List_fromArray(
									[
										function () {
										var _v3 = starData.jumpShadow;
										if (_v3.$ === 'Just') {
											var jumpShadow = _v3.a;
											return A2(
												$mdgriffith$elm_ui$Element$el,
												_List_fromArray(
													[$mdgriffith$elm_ui$Element$centerX]),
												$mdgriffith$elm_ui$Element$text(
													A2($myrho$elm_round$Round$round, 2, jumpShadow)));
										} else {
											return $mdgriffith$elm_ui$Element$text('');
										}
									}()
									])),
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_Nil,
								A2(
									$elm$core$List$map,
									function (so) {
										return A7($author$project$Traveller$StellarObjectView$renderStellarObject, msgs, surveyIndex, nextNestingLevel, so, jumpShadowCheckers, selectedStellarObject, isReferee);
									},
									A2(
										$elm$core$List$filter,
										isKnown,
										A2(
											$elm$core$List$filter,
											A2($elm$core$Basics$composeL, $elm$core$Basics$not, inJumpShadow),
											A2($elm$core$List$filter, isDisplayable, starData.stellarObjects)))))
							]);
					}())
				]));
	});
var $author$project$Traveller$StellarObjectView$renderStellarObject = F7(
	function (msgs, surveyIndex, newNestingLevel, stellarObject, jumpShadowCheckers, selectedStellarObject, isReferee) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(8),
					$mdgriffith$elm_ui$Element$Font$size(14),
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
				]),
			_List_fromArray(
				[
					function () {
					switch (stellarObject.$) {
						case 'GasGiant':
							var gasGiantData = stellarObject.a;
							return A6($author$project$Traveller$StellarObjectView$renderGasGiant, msgs, newNestingLevel, gasGiantData, jumpShadowCheckers, selectedStellarObject, isReferee);
						case 'TerrestrialPlanet':
							var terrestrialData = stellarObject.a;
							return A6($author$project$Traveller$StellarObjectView$renderTerrestrialPlanet, msgs, newNestingLevel, terrestrialData, jumpShadowCheckers, selectedStellarObject, isReferee);
						case 'PlanetoidBelt':
							var planetoidBeltData = stellarObject.a;
							return A6($author$project$Traveller$StellarObjectView$renderPlanetoidBelt, msgs, newNestingLevel, planetoidBeltData, jumpShadowCheckers, selectedStellarObject, isReferee);
						case 'Planetoid':
							var planetoidData = stellarObject.a;
							return A6($author$project$Traveller$StellarObjectView$renderPlanetoid, msgs, newNestingLevel, planetoidData, jumpShadowCheckers, selectedStellarObject, isReferee);
						default:
							var starDataConfig = stellarObject.a;
							return A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$paddingEach(
										{bottom: 5, left: 0, right: 0, top: 0})
									]),
								A7($author$project$Traveller$StellarObjectView$displayStarDetails, msgs, surveyIndex, starDataConfig, newNestingLevel, jumpShadowCheckers, selectedStellarObject, isReferee));
					}
				}()
				]));
	});
var $author$project$Traveller$StellarObject$getStarData = function (stellarObject) {
	if (stellarObject.$ === 'Star') {
		var starData = stellarObject.a;
		return $elm$core$Maybe$Just(starData);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Traveller$Sidebar$viewSystemDetailsSidebar = F4(
	function (msgs, solarSystem, selectedStellarObject, isReferee) {
		var stellarObjectMsgs = {onFocusInSidebar: msgs.focusInSidebar, onViewDetail: msgs.viewDetail};
		var jumpShadowCheckers = A2(
			$elm$core$List$map,
			F2(
				function (star, so) {
					var objToStarKMs = A2(
						$author$project$Traveller$TravelCalculations$calcDistance2F,
						star.orbitPosition,
						$author$project$Traveller$StellarObject$getStellarOrbit(so).orbitPosition);
					var jumpShadowDistanceKMs = A2($elm$core$Maybe$withDefault, 0, star.jumpShadow);
					return (_Utils_cmp(objToStarKMs, jumpShadowDistanceKMs) > 0) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
						A2($author$project$Traveller$TravelCalculations$travelTimeInSeconds, jumpShadowDistanceKMs - objToStarKMs, 4));
				}),
			A2(
				$elm$core$List$filterMap,
				A2(
					$elm$core$Basics$composeR,
					$author$project$Traveller$StellarObject$getStarData,
					$elm$core$Maybe$map($author$project$Traveller$StellarObject$getInnerStarData)),
				A2(
					$elm$core$List$cons,
					$author$project$Traveller$StellarObject$Star(solarSystem.primaryStar),
					$author$project$Traveller$StellarObject$getInnerStarData(solarSystem.primaryStar).stellarObjects)));
		return A7($author$project$Traveller$StellarObjectView$displayStarDetails, stellarObjectMsgs, solarSystem.surveyIndex, solarSystem.primaryStar, 0, jumpShadowCheckers, selectedStellarObject, isReferee);
	});
var $author$project$Traveller$Sidebar$viewSidebarColumn = F2(
	function (msgs, _v0) {
		var hexScale = _v0.hexScale;
		var isHexMapMode = _v0.isHexMapMode;
		var isFullJourneyMode = _v0.isFullJourneyMode;
		var selectedHex = _v0.selectedHex;
		var solarSystemStatus = _v0.solarSystemStatus;
		var sectors = _v0.sectors;
		var regions = _v0.regions;
		var selectedSystem = _v0.selectedSystem;
		var selectedStellarObject = _v0.selectedStellarObject;
		var isReferee = _v0.isReferee;
		return A2(
			$mdgriffith$elm_ui$Element$column,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$spacing(10),
					$mdgriffith$elm_ui$Element$centerX,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$column,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
						]),
					_List_fromArray(
						[
							function () {
							var clickableIcon = function (size) {
								var selectorColor = (_Utils_eq(hexScale, size / 2) && isHexMapMode) ? $author$project$Traveller$UI$deepnightColor : $author$project$Traveller$UI$textColor;
								var hexStyle = (_Utils_eq(hexScale, size / 2) && isHexMapMode) ? 'fa-regular' : 'fa-thin';
								return A2(
									$mdgriffith$elm_ui$Element$el,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$pointer,
											$mdgriffith$elm_ui$Element$mouseOver(
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$Font$color(
													$author$project$Traveller$StellarObjectView$convertColor(
														A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.15, selectorColor)))
												])),
											$mdgriffith$elm_ui$Element$Events$onClick(
											msgs.setHexSize(size / 2)),
											$mdgriffith$elm_ui$Element$Font$color(
											$author$project$Traveller$StellarObjectView$convertColor(selectorColor))
										]),
									A2(
										$author$project$Traveller$Sidebar$renderFAIcon,
										hexStyle + ' fa-hexagon',
										$elm$core$Basics$floor(size)));
							};
							return A2(
								$mdgriffith$elm_ui$Element$row,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$spacing(6),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										clickableIcon(80),
										clickableIcon(60),
										clickableIcon(50),
										clickableIcon(30),
										function () {
										var selectorColor = isFullJourneyMode ? $author$project$Traveller$UI$deepnightColor : $author$project$Traveller$UI$textColor;
										var hexStyle = isFullJourneyMode ? 'fa-regular' : 'fa-thin';
										return A2(
											$mdgriffith$elm_ui$Element$el,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width(
													$mdgriffith$elm_ui$Element$px(50)),
													$mdgriffith$elm_ui$Element$height(
													$mdgriffith$elm_ui$Element$px(50)),
													$mdgriffith$elm_ui$Element$pointer,
													$mdgriffith$elm_ui$Element$Events$onClick(msgs.toggleHexmap),
													$mdgriffith$elm_ui$Element$mouseOver(
													_List_fromArray(
														[
															$mdgriffith$elm_ui$Element$Font$color(
															$author$project$Traveller$StellarObjectView$convertColor(
																A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.15, selectorColor)))
														])),
													$mdgriffith$elm_ui$Element$Font$color(
													$author$project$Traveller$StellarObjectView$convertColor(selectorColor))
												]),
											A2($author$project$Traveller$Sidebar$renderFAIcon, hexStyle + (' ' + 'fa-map'), 50));
									}()
									]));
						}(),
							function () {
							if (selectedHex.$ === 'Just') {
								var viewingAddress = selectedHex.a;
								return A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$centerY,
											A2($mdgriffith$elm_ui$Element$paddingXY, 0, 10),
											$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
										]),
									_List_fromArray(
										[
											function () {
											if (solarSystemStatus.$ === 'Just') {
												var status = solarSystemStatus.a;
												return $mdgriffith$elm_ui$Element$text(status);
											} else {
												return $mdgriffith$elm_ui$Element$none;
											}
										}(),
											A2(
											$mdgriffith$elm_ui$Element$row,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$spacing(5),
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
												]),
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$text(
													A2($author$project$Traveller$Sidebar$universalHexLabel, sectors, viewingAddress)),
													A2(
													$mdgriffith$elm_ui$Element$column,
													_List_fromArray(
														[$mdgriffith$elm_ui$Element$alignRight]),
													A2(
														$elm$core$List$filterMap,
														function (region) {
															return A2($elm$core$List$member, viewingAddress, region.hexes) ? $elm$core$Maybe$Just(
																A2(
																	$mdgriffith$elm_ui$Element$el,
																	_List_fromArray(
																		[
																			$mdgriffith$elm_ui$Element$Font$size(12),
																			$mdgriffith$elm_ui$Element$Font$color(
																			$author$project$Traveller$StellarObjectView$convertColor(region.colour))
																		]),
																	$mdgriffith$elm_ui$Element$text(region.name))) : $elm$core$Maybe$Nothing;
														},
														$elm$core$Dict$values(regions)))
												]))
										]));
							} else {
								return A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$centerX,
											$mdgriffith$elm_ui$Element$centerY,
											$mdgriffith$elm_ui$Element$Font$size(10)
										]),
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$text('Select hex in console to view parsec details.')
										]));
							}
						}(),
							function () {
							if (selectedSystem.$ === 'Just') {
								var solarSystem = selectedSystem.a;
								return A5($mdgriffith$elm_ui$Element$Lazy$lazy4, $author$project$Traveller$Sidebar$viewSystemDetailsSidebar, msgs, solarSystem, selectedStellarObject, isReferee);
							} else {
								return A2(
									$mdgriffith$elm_ui$Element$column,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$centerX,
											$mdgriffith$elm_ui$Element$centerY,
											$mdgriffith$elm_ui$Element$Font$size(10),
											$mdgriffith$elm_ui$Element$moveDown(20)
										]),
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$text('Click a hex to view system details.')
										]));
							}
						}()
						])),
					A2($mdgriffith$elm_ui$Element$Lazy$lazy, $author$project$Traveller$Sidebar$viewSidebarFooter, selectedHex)
				]));
	});
var $author$project$Traveller$JumpToShip = {$: 'JumpToShip'};
var $author$project$Traveller$Zoom = function (a) {
	return {$: 'Zoom', a: a};
};
var $author$project$Traveller$ZoomIn = {$: 'ZoomIn'};
var $author$project$Traveller$ZoomOut = {$: 'ZoomOut'};
var $author$project$Traveller$ZoomSet = function (a) {
	return {$: 'ZoomSet', a: a};
};
var $author$project$Traveller$conditionalAttribute = F2(
	function (condition, attribute) {
		return condition ? attribute : $author$project$Traveller$noopAttribute;
	});
var $author$project$Traveller$renderFAIcon = F2(
	function (icon, size) {
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(size)),
					$mdgriffith$elm_ui$Element$height(
					$mdgriffith$elm_ui$Element$px(size))
				]),
			$mdgriffith$elm_ui$Element$html(
				A2(
					$elm$html$Html$i,
					_List_fromArray(
						[
							A2(
							$elm$html$Html$Attributes$style,
							'font-size',
							$elm$core$String$fromInt(size) + 'px'),
							$elm$html$Html$Attributes$class(icon)
						]),
					_List_Nil)));
	});
var $elm$html$Html$Attributes$title = $elm$html$Html$Attributes$stringProperty('title');
var $mdgriffith$elm_ui$Internal$Model$Transparency = F2(
	function (a, b) {
		return {$: 'Transparency', a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$transparency = $mdgriffith$elm_ui$Internal$Flag$flag(0);
var $mdgriffith$elm_ui$Element$transparent = function (on) {
	return on ? A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$transparency,
		A2($mdgriffith$elm_ui$Internal$Model$Transparency, 'transparent', 1.0)) : A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$transparency,
		A2($mdgriffith$elm_ui$Internal$Model$Transparency, 'visible', 0.0));
};
var $author$project$Traveller$universalHexLabel = F2(
	function (sectors, hexAddress) {
		var _v0 = A2(
			$elm$core$Dict$get,
			$author$project$Traveller$HexAddress$toSectorKey(
				$author$project$Traveller$HexAddress$toSectorAddress(hexAddress)),
			sectors);
		if (_v0.$ === 'Nothing') {
			return ' ';
		} else {
			var sector = _v0.a;
			return sector.name + (' ' + $author$project$Traveller$HexAddress$hexLabel(hexAddress));
		}
	});
var $author$project$Traveller$universalHexLabelMaybe = F2(
	function (sectors, hexAddress) {
		return A2(
			$elm$core$Maybe$map,
			function (sector) {
				return sector.name + (' ' + $author$project$Traveller$HexAddress$hexLabel(hexAddress));
			},
			A2(
				$elm$core$Dict$get,
				$author$project$Traveller$HexAddress$toSectorKey(
					$author$project$Traveller$HexAddress$toSectorAddress(hexAddress)),
				sectors));
	});
var $mdgriffith$elm_ui$Internal$Model$Padding = F5(
	function (a, b, c, d, e) {
		return {$: 'Padding', a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Internal$Model$Spaced = F3(
	function (a, b, c) {
		return {$: 'Spaced', a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$extractSpacingAndPadding = function (attrs) {
	return A3(
		$elm$core$List$foldr,
		F2(
			function (attr, _v0) {
				var pad = _v0.a;
				var spacing = _v0.b;
				return _Utils_Tuple2(
					function () {
						if (pad.$ === 'Just') {
							var x = pad.a;
							return pad;
						} else {
							if ((attr.$ === 'StyleClass') && (attr.b.$ === 'PaddingStyle')) {
								var _v3 = attr.b;
								var name = _v3.a;
								var t = _v3.b;
								var r = _v3.c;
								var b = _v3.d;
								var l = _v3.e;
								return $elm$core$Maybe$Just(
									A5($mdgriffith$elm_ui$Internal$Model$Padding, name, t, r, b, l));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}
					}(),
					function () {
						if (spacing.$ === 'Just') {
							var x = spacing.a;
							return spacing;
						} else {
							if ((attr.$ === 'StyleClass') && (attr.b.$ === 'SpacingStyle')) {
								var _v6 = attr.b;
								var name = _v6.a;
								var x = _v6.b;
								var y = _v6.c;
								return $elm$core$Maybe$Just(
									A3($mdgriffith$elm_ui$Internal$Model$Spaced, name, x, y));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}
					}());
			}),
		_Utils_Tuple2($elm$core$Maybe$Nothing, $elm$core$Maybe$Nothing),
		attrs);
};
var $mdgriffith$elm_ui$Internal$Model$paddingNameFloat = F4(
	function (top, right, bottom, left) {
		return 'pad-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(top) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(right) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(bottom) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(left)))))));
	});
var $mdgriffith$elm_ui$Element$wrappedRow = F2(
	function (attrs, children) {
		var _v0 = $mdgriffith$elm_ui$Internal$Model$extractSpacingAndPadding(attrs);
		var padded = _v0.a;
		var spaced = _v0.b;
		if (spaced.$ === 'Nothing') {
			return A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asRow,
				$mdgriffith$elm_ui$Internal$Model$div,
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentLeft + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.wrapped)))),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
							attrs))),
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
		} else {
			var _v2 = spaced.a;
			var spaceName = _v2.a;
			var x = _v2.b;
			var y = _v2.c;
			var newPadding = function () {
				if (padded.$ === 'Just') {
					var _v5 = padded.a;
					var name = _v5.a;
					var t = _v5.b;
					var r = _v5.c;
					var b = _v5.d;
					var l = _v5.e;
					if ((_Utils_cmp(r, x / 2) > -1) && (_Utils_cmp(b, y / 2) > -1)) {
						var newTop = t - (y / 2);
						var newRight = r - (x / 2);
						var newLeft = l - (x / 2);
						var newBottom = b - (y / 2);
						return $elm$core$Maybe$Just(
							A2(
								$mdgriffith$elm_ui$Internal$Model$StyleClass,
								$mdgriffith$elm_ui$Internal$Flag$padding,
								A5(
									$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
									A4($mdgriffith$elm_ui$Internal$Model$paddingNameFloat, newTop, newRight, newBottom, newLeft),
									newTop,
									newRight,
									newBottom,
									newLeft)));
					} else {
						return $elm$core$Maybe$Nothing;
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}();
			if (newPadding.$ === 'Just') {
				var pad = newPadding.a;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asRow,
					$mdgriffith$elm_ui$Internal$Model$div,
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentLeft + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.wrapped)))),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
								_Utils_ap(
									attrs,
									_List_fromArray(
										[pad]))))),
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
			} else {
				var halfY = -(y / 2);
				var halfX = -(x / 2);
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asEl,
					$mdgriffith$elm_ui$Internal$Model$div,
					attrs,
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(
						_List_fromArray(
							[
								A4(
								$mdgriffith$elm_ui$Internal$Model$element,
								$mdgriffith$elm_ui$Internal$Model$asRow,
								$mdgriffith$elm_ui$Internal$Model$div,
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.contentLeft + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.contentCenterY + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.wrapped)))),
									A2(
										$elm$core$List$cons,
										$mdgriffith$elm_ui$Internal$Model$Attr(
											A2(
												$elm$html$Html$Attributes$style,
												'margin',
												$elm$core$String$fromFloat(halfY) + ('px' + (' ' + ($elm$core$String$fromFloat(halfX) + 'px'))))),
										A2(
											$elm$core$List$cons,
											$mdgriffith$elm_ui$Internal$Model$Attr(
												A2(
													$elm$html$Html$Attributes$style,
													'width',
													'calc(100% + ' + ($elm$core$String$fromInt(x) + 'px)'))),
											A2(
												$elm$core$List$cons,
												$mdgriffith$elm_ui$Internal$Model$Attr(
													A2(
														$elm$html$Html$Attributes$style,
														'height',
														'calc(100% + ' + ($elm$core$String$fromInt(y) + 'px)'))),
												A2(
													$elm$core$List$cons,
													A2(
														$mdgriffith$elm_ui$Internal$Model$StyleClass,
														$mdgriffith$elm_ui$Internal$Flag$spacing,
														A3($mdgriffith$elm_ui$Internal$Model$SpacingStyle, spaceName, x, y)),
													_List_Nil))))),
								$mdgriffith$elm_ui$Internal$Model$Unkeyed(children))
							])));
			}
		}
	});
var $author$project$Traveller$viewStatusRow = function (model) {
	var extras = function () {
		var _v0 = model.viewMode;
		if (_v0.$ === 'HexMap') {
			return _List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$spacing(5),
							$mdgriffith$elm_ui$Element$pointer,
							$mdgriffith$elm_ui$Element$Events$onClick($author$project$Traveller$DownloadSolarSystems),
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$htmlAttribute(
							$elm$html$Html$Attributes$title('Refresh map')),
							$mdgriffith$elm_ui$Element$mouseOver(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$color(
									$author$project$Traveller$StellarObjectView$convertColor(
										A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.25, $author$project$Traveller$UI$deepnightColor)))
								]))
						]),
					A2($author$project$Traveller$renderFAIcon, 'fa-regular fa-refresh', 14)),
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$family(
							_List_fromArray(
								[$mdgriffith$elm_ui$Element$Font$monospace])),
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$width(
							A2($mdgriffith$elm_ui$Element$minimum, 10, $mdgriffith$elm_ui$Element$shrink))
						]),
					function () {
						var _v1 = model.hoveringHex;
						if (_v1.$ === 'Just') {
							var hoveringHex = _v1.a;
							return $mdgriffith$elm_ui$Element$text(
								A2($author$project$Traveller$universalHexLabel, model.sectors, hoveringHex));
						} else {
							return $mdgriffith$elm_ui$Element$none;
						}
					}()),
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$centerX
						]),
					$mdgriffith$elm_ui$Element$text(
						function () {
							var last = A2(
								$author$project$Traveller$HexAddress$shiftAddressBy,
								{deltaX: -3, deltaY: -1},
								model.hexRect.lowerRightHex);
							var first = A2(
								$author$project$Traveller$HexAddress$shiftAddressBy,
								{deltaX: 1, deltaY: 1},
								model.hexRect.upperLeftHex);
							return A2(
								$elm$core$Maybe$withDefault,
								'???',
								A2($author$project$Traveller$universalHexLabelMaybe, model.sectors, first)) + (' – ' + A2(
								$elm$core$Maybe$withDefault,
								'???',
								A2($author$project$Traveller$universalHexLabelMaybe, model.sectors, last)));
						}())),
					A2(
					$mdgriffith$elm_ui$Element$row,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$spacing(5),
							$mdgriffith$elm_ui$Element$pointer,
							$mdgriffith$elm_ui$Element$Events$onClick($author$project$Traveller$JumpToShip),
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$mouseOver(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$color(
									$author$project$Traveller$StellarObjectView$convertColor(
										A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.25, $author$project$Traveller$UI$deepnightColor)))
								]))
						]),
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$text(model.shipName),
							A2($author$project$Traveller$renderFAIcon, 'fa-regular fa-crosshairs-simple', 14),
							$mdgriffith$elm_ui$Element$text(
							A2(
								$elm$core$Maybe$withDefault,
								'???',
								A2($author$project$Traveller$universalHexLabelMaybe, model.sectors, model.currentAddress)))
						]))
				]);
		} else {
			return _List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$spacing(5),
							$mdgriffith$elm_ui$Element$pointer,
							$mdgriffith$elm_ui$Element$transparent(model.journeyModel.zoomScale <= 1.0),
							$author$project$Traveller$userSelectNone,
							A2(
							$author$project$Traveller$conditionalAttribute,
							model.journeyModel.zoomScale > 1.0,
							$mdgriffith$elm_ui$Element$Events$onClick(
								$author$project$Traveller$JourneyMsg(
									$author$project$Traveller$Zoom($author$project$Traveller$ZoomOut)))),
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$mouseOver(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$color(
									$author$project$Traveller$StellarObjectView$convertColor(
										A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.25, $author$project$Traveller$UI$deepnightColor)))
								]))
						]),
					A2($author$project$Traveller$renderFAIcon, 'fa-regular fa-magnifying-glass-minus', 14)),
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$Font$family(
							_List_fromArray(
								[$mdgriffith$elm_ui$Element$Font$monospace])),
							$author$project$Traveller$userSelectNone
						]),
					function () {
						var roundedZoom = $elm$core$Basics$ceiling(model.journeyModel.zoomScale);
						var zoomAscii = A2(
							$elm$core$List$indexedMap,
							F2(
								function (i, r) {
									return _Utils_eq(r, roundedZoom) ? $mdgriffith$elm_ui$Element$text('|') : A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$pointer,
												$mdgriffith$elm_ui$Element$Events$onClick(
												$author$project$Traveller$JourneyMsg(
													$author$project$Traveller$Zoom(
														$author$project$Traveller$ZoomSet(
															A2($elm$core$Basics$pow, 1.5, i))))),
												$mdgriffith$elm_ui$Element$mouseOver(
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$Font$color(
														$author$project$Traveller$StellarObjectView$convertColor(
															A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.25, $author$project$Traveller$UI$deepnightColor)))
													]))
											]),
										$mdgriffith$elm_ui$Element$text('-'));
								}),
							_List_fromArray(
								[1, 2, 3, 4, 6, 8]));
						return A2($mdgriffith$elm_ui$Element$row, _List_Nil, zoomAscii);
					}()),
					A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$author$project$Traveller$UI$uiDeepnightColorFontColour,
							$mdgriffith$elm_ui$Element$Font$size(14),
							$mdgriffith$elm_ui$Element$spacing(5),
							$mdgriffith$elm_ui$Element$pointer,
							A2(
							$author$project$Traveller$conditionalAttribute,
							model.journeyModel.zoomScale < 7.0,
							$mdgriffith$elm_ui$Element$Events$onClick(
								$author$project$Traveller$JourneyMsg(
									$author$project$Traveller$Zoom($author$project$Traveller$ZoomIn)))),
							$mdgriffith$elm_ui$Element$transparent(model.journeyModel.zoomScale >= 7.0),
							$author$project$Traveller$userSelectNone,
							$mdgriffith$elm_ui$Element$alignBottom,
							$mdgriffith$elm_ui$Element$mouseOver(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$color(
									$author$project$Traveller$StellarObjectView$convertColor(
										A2($noahzgordon$elm_color_extra$Color$Manipulate$lighten, 0.25, $author$project$Traveller$UI$deepnightColor)))
								]))
						]),
					A2($author$project$Traveller$renderFAIcon, 'fa-regular fa-magnifying-glass-plus', 14))
				]);
		}
	}();
	return A2(
		$mdgriffith$elm_ui$Element$wrappedRow,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$spacing(8),
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$paddingEach(
				_Utils_update(
					$author$project$Traveller$UI$zeroEach,
					{bottom: 8}))
			]),
		A2(
			$elm$core$List$cons,
			A2(
				$mdgriffith$elm_ui$Element$el,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$Font$size(20),
						$author$project$Traveller$UI$uiDeepnightColorFontColour
					]),
				$mdgriffith$elm_ui$Element$text(model.campaignName)),
			extras));
};
var $author$project$Traveller$view = function (_v0) {
	var time = _v0.a;
	var model = _v0.b;
	var timeChars = (($elm$time$Time$posixToMillis(time) - $elm$time$Time$posixToMillis(model.timeOpened)) / 20) | 0;
	var solarSystemStatus = function () {
		var _v3 = model.selectedHex;
		if (_v3.$ === 'Just') {
			var viewingAddress = _v3.a;
			var _v4 = A2(
				$elm$core$Dict$get,
				$author$project$Traveller$HexAddress$toKey(viewingAddress),
				model.solarSystems);
			if (_v4.$ === 'Just') {
				switch (_v4.a.$) {
					case 'LoadingSolarSystem':
						var _v5 = _v4.a;
						return $elm$core$Maybe$Just('loading...');
					case 'FailedSolarSystem':
						return $elm$core$Maybe$Just('failed.');
					case 'FailedStarsSolarSystem':
						return $elm$core$Maybe$Just('decoding a star failed');
					default:
						return $elm$core$Maybe$Nothing;
				}
			} else {
				return $elm$core$Maybe$Just('No solar system data found for system.');
			}
		} else {
			return $elm$core$Maybe$Nothing;
		}
	}();
	var sidebarMsgs = {focusInSidebar: $author$project$Traveller$FocusInSidebar, setHexSize: $author$project$Traveller$SetHexSize, toggleHexmap: $author$project$Traveller$ToggleHexmap, viewDetail: $author$project$Traveller$ViewObjectAnalysisDetail};
	var sidebarData = {
		hexScale: model.hexScale,
		isFullJourneyMode: _Utils_eq(model.viewMode, $author$project$Traveller$FullJourney),
		isHexMapMode: _Utils_eq(model.viewMode, $author$project$Traveller$HexMap),
		isReferee: model.isReferee,
		regions: model.regions,
		sectors: model.sectors,
		selectedHex: model.selectedHex,
		selectedStellarObject: model.selectedStellarObject,
		selectedSystem: model.selectedSystem,
		solarSystemStatus: solarSystemStatus
	};
	var sidebarColumn = A3($mdgriffith$elm_ui$Element$Lazy$lazy2, $author$project$Traveller$Sidebar$viewSidebarColumn, sidebarMsgs, sidebarData);
	var contentColumn = function () {
		var _v2 = model.viewMode;
		if (_v2.$ === 'HexMap') {
			return $author$project$Traveller$viewHexMap(model);
		} else {
			return A2($author$project$Traveller$viewFullJourney, model.journeyModel, model.viewport.viewport);
		}
	}();
	return A2(
		$mdgriffith$elm_ui$Element$row,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$Font$size(20),
				$mdgriffith$elm_ui$Element$Font$color($author$project$Traveller$UI$fontTextColor),
				$mdgriffith$elm_ui$Element$Background$color(
				A3($mdgriffith$elm_ui$Element$rgb255, 33, 37, 41)),
				A2($mdgriffith$elm_ui$Element$paddingXY, 15, 0),
				function () {
				var _v1 = model.objectToBeAnalyzed;
				if (_v1.$ === 'Just') {
					var analysisDetail = _v1.a;
					return $mdgriffith$elm_ui$Element$inFront(
						A3($author$project$Traveller$AnalysisDetail$viewObjectAnalysisDetail, timeChars, $author$project$Traveller$CloseObjectAnalysis, analysisDetail.data));
				} else {
					return $mdgriffith$elm_ui$Element$htmlAttribute(
						$elm$html$Html$Attributes$class(''));
				}
			}()
			]),
		_List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Element$el,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width(
						$mdgriffith$elm_ui$Element$px($author$project$Traveller$Sidebar$sidebarWidth)),
						$mdgriffith$elm_ui$Element$alignTop,
						$mdgriffith$elm_ui$Element$alignLeft
					]),
				sidebarColumn),
				A2(
				$mdgriffith$elm_ui$Element$column,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
					]),
				_List_fromArray(
					[
						$author$project$Traveller$viewStatusRow(model),
						A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[$mdgriffith$elm_ui$Element$alignTop]),
						contentColumn)
					])),
				$mdgriffith$elm_ui$Element$html(
				$author$project$Traveller$errorDialog(model.newSolarSystemErrors))
			]));
};
var $author$project$Main$view = function (model) {
	return {
		body: _List_fromArray(
			[
				A3($author$project$Dialog$view, 'error-dialog', $author$project$Main$ToggleErrorDialog, model.dialogBody),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						A2($elm$html$Html$Attributes$style, 'padding', '8px 0px')
					]),
				_List_fromArray(
					[
						$author$project$Main$elmUiHackLayout,
						function () {
						var _v0 = model.travellerModel;
						if (_v0.$ === 'Just') {
							var tm = _v0.a;
							return A2(
								$elm$html$Html$map,
								$author$project$Main$GotTravellerMsg,
								A3(
									$mdgriffith$elm_ui$Element$layoutWith,
									{
										options: _List_fromArray(
											[$mdgriffith$elm_ui$Element$noStaticStyleSheet])
									},
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$centerX,
											$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
										]),
									$author$project$Traveller$view(tm)));
						} else {
							return A2(
								$elm$html$Html$div,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('Loading')
									]));
						}
					}()
					]))
			]),
		title: A2($elm$core$Maybe$withDefault, 'Starmap', model.flags.shipName)
	};
};
var $author$project$Main$main = $elm$browser$Browser$application(
	{init: $author$project$Main$init, onUrlChange: $author$project$Main$UrlChanged, onUrlRequest: $author$project$Main$LinkClicked, subscriptions: $author$project$Main$subscriptions, update: $author$project$Main$update, view: $author$project$Main$view});
_Platform_export({'Main':{'init':$author$project$Main$main(
	A2(
		$elm$json$Json$Decode$andThen,
		function (upperLeft) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (shipName) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (referee) {
							return A2(
								$elm$json$Json$Decode$andThen,
								function (hexSize) {
									return A2(
										$elm$json$Json$Decode$andThen,
										function (campaignSlug) {
											return A2(
												$elm$json$Json$Decode$andThen,
												function (campaignName) {
													return A2(
														$elm$json$Json$Decode$andThen,
														function (apiBaseUrl) {
															return $elm$json$Json$Decode$succeed(
																{apiBaseUrl: apiBaseUrl, campaignName: campaignName, campaignSlug: campaignSlug, hexSize: hexSize, referee: referee, shipName: shipName, upperLeft: upperLeft});
														},
														A2($elm$json$Json$Decode$field, 'apiBaseUrl', $elm$json$Json$Decode$string));
												},
												A2(
													$elm$json$Json$Decode$field,
													'campaignName',
													$elm$json$Json$Decode$oneOf(
														_List_fromArray(
															[
																$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
																A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, $elm$json$Json$Decode$string)
															]))));
										},
										A2($elm$json$Json$Decode$field, 'campaignSlug', $elm$json$Json$Decode$string));
								},
								A2($elm$json$Json$Decode$field, 'hexSize', $elm$json$Json$Decode$float));
						},
						A2($elm$json$Json$Decode$field, 'referee', $elm$json$Json$Decode$bool));
				},
				A2(
					$elm$json$Json$Decode$field,
					'shipName',
					$elm$json$Json$Decode$oneOf(
						_List_fromArray(
							[
								$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
								A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, $elm$json$Json$Decode$string)
							]))));
		},
		A2(
			$elm$json$Json$Decode$field,
			'upperLeft',
			$elm$json$Json$Decode$oneOf(
				_List_fromArray(
					[
						$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
						A2(
						$elm$json$Json$Decode$map,
						$elm$core$Maybe$Just,
						A2(
							$elm$json$Json$Decode$andThen,
							function (_v0) {
								return A2(
									$elm$json$Json$Decode$andThen,
									function (_v1) {
										return $elm$json$Json$Decode$succeed(
											_Utils_Tuple2(_v0, _v1));
									},
									A2($elm$json$Json$Decode$index, 1, $elm$json$Json$Decode$int));
							},
							A2($elm$json$Json$Decode$index, 0, $elm$json$Json$Decode$int)))
					])))))(0)}});}(this));