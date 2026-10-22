import "../css/app.css";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
import FeedHooks from "./hooks/feed/index.js";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {...FeedHooks},
});
liveSocket.connect();
