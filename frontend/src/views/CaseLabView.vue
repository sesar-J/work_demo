<script setup>
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { createLabSession, fetchCaseBySlug, fetchTerraformTemplate } from "../api";

const route = useRoute();
const router = useRouter();
const loading = ref(false);
const item = ref(null);
const error = ref("");
const notebookLoaded = ref(false);
const notebookUrl = ref("");
const sessionInfo = ref("");
const starting = ref(false);
const terraform = ref(null);
const showCredentialPanel = ref(false);
const form = ref({
  ak: "",
  sk: "",
});

onMounted(async () => {
  loading.value = true;
  error.value = "";
  try {
    item.value = await fetchCaseBySlug(route.params.slug);
    terraform.value = await fetchTerraformTemplate();
    await startLab();
  } catch (e) {
    error.value = "加载操作页失败。";
  } finally {
    loading.value = false;
  }
});

async function startLab() {
  if ((form.value.ak && !form.value.sk) || (!form.value.ak && form.value.sk)) {
    sessionInfo.value = "AK 和 SK 需要同时填写。";
    return;
  }

  starting.value = true;
  sessionInfo.value = "";
  try {
    const payload = {
      case_slug: route.params.slug,
    };
    if (form.value.ak && form.value.sk) {
      payload.ak = form.value.ak;
      payload.sk = form.value.sk;
    }

    const data = await createLabSession({
      ...payload,
    });
    notebookUrl.value = data.notebook_url;
    notebookLoaded.value = true;
    sessionInfo.value = `独立环境已就绪，会话ID: ${data.session_id}`;
  } catch (e) {
    sessionInfo.value = "启动环境失败，请检查参数后重试。";
    notebookLoaded.value = true;
    if (item.value?.notebook_iframe_url) {
      notebookUrl.value = item.value.notebook_iframe_url;
    }
  } finally {
    starting.value = false;
  }
}
</script>

<template>
  <div class="page">
    <div class="topbar">
      <div class="topbar-inner">
        <button @click="router.push(`/cases/${route.params.slug}`)">返回详情</button>
        <span class="hint">左侧阅读步骤，右侧直接实操。环境进入页面后自动启动。</span>
      </div>
    </div>
    <p v-if="loading" class="state-text">加载中...</p>
    <p v-else-if="error" class="state-text error">{{ error }}</p>
    <div v-else-if="item" class="split-layout">
      <section class="left-doc">
        <div class="doc-header">
          <p class="doc-eyebrow">LAB GUIDE</p>
          <h2>{{ item.title }} - 操作文档</h2>
          <p class="doc-subtitle">建议先阅读完整步骤，再在右侧 Notebook 分段执行，避免中途配置遗漏。</p>
        </div>
        <div class="terraform-block" v-if="terraform">
          <h3>统一 Terraform 环境模板</h3>
          <p>所有案例统一使用以下模板结构：</p>
          <ul>
            <li><code>versions.tf</code></li>
            <li><code>provider.tf</code></li>
            <li><code>variables.tf</code></li>
            <li><code>main.tf</code></li>
            <li><code>terraform.tfvars</code></li>
          </ul>
        </div>
        <div class="markdown-content doc-content" v-html="item.operation_html"></div>
      </section>
      <section class="right-lab">
        <div class="lab-toolbar">
          <div>
            <p class="toolbar-title">Notebook 实操区</p>
            <p class="session-info" v-if="sessionInfo">{{ sessionInfo }}</p>
          </div>
          <button class="secondary-btn" @click="showCredentialPanel = !showCredentialPanel">
            {{ showCredentialPanel ? "收起 AK/SK 配置" : "配置 AK/SK" }}
          </button>
        </div>

        <div v-if="showCredentialPanel" class="credential-panel">
          <div class="form">
            <input v-model.trim="form.ak" placeholder="输入 AK（可选）" />
            <input v-model.trim="form.sk" placeholder="输入 SK（可选）" type="password" />
          </div>
          <button class="primary-btn" :disabled="starting" @click="startLab">
            {{ starting ? "更新中..." : "使用 AK/SK 更新环境" }}
          </button>
        </div>

        <div v-if="!notebookLoaded" class="loading-placeholder">环境启动中，请稍候...</div>
        <iframe
          v-if="notebookLoaded"
          :src="notebookUrl || item.notebook_iframe_url"
          title="Jupyter Notebook"
          loading="lazy"
          allowfullscreen
          class="notebook-frame"
        ></iframe>
      </section>
    </div>
  </div>
</template>

<style scoped>
.page {
  height: calc(100vh - 56px);
  display: flex;
  flex-direction: column;
  background: #eef2f8;
}

.topbar {
  padding: 10px 14px;
  border-bottom: 1px solid #e5e7eb;
  background: rgba(255, 255, 255, 0.88);
  backdrop-filter: blur(6px);
}

.topbar-inner {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 12px;
}

.topbar button {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 10px;
  padding: 7px 12px;
  cursor: pointer;
}

.hint {
  font-size: 13px;
  color: #64748b;
}

.split-layout {
  flex: 1;
  display: grid;
  grid-template-columns: 45% 55%;
  min-height: 0;
  padding: 12px;
  gap: 12px;
}

.left-doc {
  padding: 18px;
  overflow: auto;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
}

.left-doc h2 {
  margin: 6px 0 10px;
  font-size: 22px;
  line-height: 1.4;
}

.doc-header {
  margin-bottom: 14px;
  padding: 14px;
  border: 1px solid #dbeafe;
  border-radius: 12px;
  background: linear-gradient(135deg, #eff6ff, #f8fbff);
}

.doc-eyebrow {
  margin: 0;
  font-size: 11px;
  letter-spacing: 1px;
  color: #2563eb;
  font-weight: 700;
}

.doc-subtitle {
  margin: 0;
  color: #475569;
  font-size: 13px;
}

.doc-content {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px;
  background: #fff;
}

.terraform-block {
  background: #f8fafc;
  border: 1px solid #dbeafe;
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 14px;
}

.terraform-block h3 {
  margin: 0 0 8px;
}

.terraform-block p {
  margin: 0 0 8px;
  color: #475569;
}

.terraform-block ul {
  margin: 0;
  padding-left: 18px;
}

.right-lab {
  min-height: 0;
  display: flex;
  flex-direction: column;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
}

.lab-toolbar {
  border-bottom: 1px solid #e5e7eb;
  padding: 10px 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.toolbar-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
}

.secondary-btn,
.primary-btn {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  background: #fff;
  padding: 8px 10px;
  font-size: 13px;
  cursor: pointer;
}

.primary-btn {
  border: none;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  color: #fff;
  font-weight: 600;
}

.credential-panel {
  border-bottom: 1px solid #e5e7eb;
  padding: 10px 12px;
  background: #f8fafc;
}

.form {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 8px;
}

.form input {
  flex: 1;
  min-width: 180px;
  border: 1px solid #d1d5db;
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 14px;
}

.primary-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.session-info {
  margin: 4px 0 0;
  font-size: 12px;
  color: #475569;
}

.loading-placeholder {
  padding: 14px;
  color: #64748b;
  font-size: 13px;
}

.notebook-frame {
  width: 100%;
  flex: 1;
  min-height: 0;
  border: none;
}

.state-text {
  margin: 12px;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 12px 14px;
}

.state-text.error {
  color: #b91c1c;
}
</style>
