<script setup>
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { fetchCaseBySlug } from "../api";

const route = useRoute();
const router = useRouter();
const loading = ref(false);
const item = ref(null);
const error = ref("");
const notebookLoaded = ref(false);

onMounted(async () => {
  loading.value = true;
  error.value = "";
  try {
    item.value = await fetchCaseBySlug(route.params.slug);
  } catch (e) {
    error.value = "加载操作页失败。";
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="page">
    <div class="topbar">
      <div class="topbar-inner">
        <button @click="router.push(`/cases/${route.params.slug}`)">返回详情</button>
        <span class="hint">左侧阅读步骤，右侧执行验证</span>
      </div>
    </div>
    <p v-if="loading" class="state-text">加载中...</p>
    <p v-else-if="error" class="state-text error">{{ error }}</p>
    <div v-else-if="item" class="split-layout">
      <section class="left-doc">
        <h2>{{ item.title }} - 操作文档</h2>
        <div v-html="item.operation_html"></div>
      </section>
      <section class="right-lab">
        <div v-if="!notebookLoaded" class="notebook-placeholder">
          <p>Notebook 环境较重，点击后再加载可减少首屏等待。</p>
          <button @click="notebookLoaded = true">加载 Notebook</button>
        </div>
        <iframe
          v-if="notebookLoaded"
          :src="item.notebook_iframe_url"
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
  background: #ffffff;
}

.left-doc h2 {
  margin-top: 0;
  font-size: 20px;
}

.right-lab {
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
}

.notebook-placeholder {
  text-align: center;
  color: #374151;
}

.notebook-placeholder button {
  margin-top: 10px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  color: #fff;
  padding: 9px 14px;
  font-weight: 600;
  cursor: pointer;
}

.notebook-frame {
  width: 100%;
  height: 100%;
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
