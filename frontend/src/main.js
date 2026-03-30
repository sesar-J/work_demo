import { createApp } from "vue";
import $ from "jquery";
import App from "./App.vue";
import router from "./router";
import "@opentiny/vue-theme/index.css";
import "./style.css";

window.$ = $;
window.jQuery = $;
document.documentElement.setAttribute("site", "china");

createApp(App).use(router).mount("#app");

function loadExternalScript(src) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.onload = resolve;
    script.onerror = reject;
    document.body.appendChild(script);
  });
}

loadExternalScript(
  "https://res-static.hc-cdn.cn/aem/content/dam/cloudbu-develop/archive/china/zh-cn/developer/developer-page/js/developer-pep2-template.js"
).catch(() => {
  // 保底：外部脚本加载失败时，不阻断本项目主流程
});
