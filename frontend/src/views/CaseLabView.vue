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
      <button @click="router.push(`/cases/${route.params.slug}`)">返回详情</button>
    </div>
    <p v-if="loading">加载中...</p>
    <p v-else-if="error">{{ error }}</p>
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
}

.topbar {
  padding: 12px;
  border-bottom: 1px solid #e5e7eb;
  background: #fff;
}

.split-layout {
  flex: 1;
  display: grid;
  grid-template-columns: 45% 55%;
  min-height: 0;
}

.left-doc {
  padding: 16px;
  overflow: auto;
  border-right: 1px solid #e5e7eb;
  background: #fff;
}

.right-lab {
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9fafb;
}

.notebook-placeholder {
  text-align: center;
  color: #374151;
}

.notebook-placeholder button {
  margin-top: 8px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  background: #fff;
  padding: 8px 12px;
  cursor: pointer;
}

.notebook-frame {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
