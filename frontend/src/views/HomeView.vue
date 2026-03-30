<script setup>
import { onMounted, ref } from "vue";
import CaseCard from "../components/CaseCard.vue";
import { fetchCases, fetchSyncStatus, triggerManualRebuild } from "../api";

const loading = ref(false);
const list = ref([]);
const error = ref("");
const syncLoading = ref(false);
const syncMessage = ref("暂无同步记录");
const syncStatus = ref("idle");

async function loadCases() {
  loading.value = true;
  error.value = "";
  try {
    list.value = await fetchCases();
  } catch (e) {
    error.value = "加载案例失败，请检查后端服务。";
  } finally {
    loading.value = false;
  }
}

async function loadSyncStatus() {
  try {
    const data = await fetchSyncStatus();
    syncStatus.value = data.status;
    syncMessage.value = data.message;
  } catch (e) {
    syncStatus.value = "error";
    syncMessage.value = "同步状态获取失败";
  }
}

async function manualSync() {
  syncLoading.value = true;
  try {
    const data = await triggerManualRebuild();
    syncStatus.value = "success";
    syncMessage.value = data.message;
    await loadCases();
  } catch (e) {
    syncStatus.value = "error";
    syncMessage.value = "手动同步失败";
  } finally {
    syncLoading.value = false;
  }
}

onMounted(async () => {
  await loadCases();
  await loadSyncStatus();
});
</script>

<template>
  <div class="page">
    <header class="hero">
      <h1>华为云 Hands-on 实践中心</h1>
      <p>从案例中快速上手云上开发与部署。</p>
    </header>

    <main>
      <div class="sync-panel">
        <button :disabled="syncLoading" @click="manualSync">
          {{ syncLoading ? "同步中..." : "手动同步案例内容" }}
        </button>
        <span class="sync-text" :class="`status-${syncStatus}`">{{ syncMessage }}</span>
      </div>

      <p v-if="loading">加载中...</p>
      <p v-else-if="error">{{ error }}</p>
      <div v-else class="grid">
        <CaseCard v-for="item in list" :key="item.slug" :case-item="item" />
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  max-width: 1120px;
  margin: 0 auto;
  padding: 24px;
}

.hero {
  margin-bottom: 20px;
}

.hero h1 {
  margin-bottom: 8px;
}

.sync-panel {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.sync-panel button {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  background: #fff;
  padding: 8px 12px;
  cursor: pointer;
}

.sync-panel button:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.sync-text {
  font-size: 14px;
  color: #6b7280;
}

.status-success {
  color: #059669;
}

.status-error {
  color: #dc2626;
}

.grid {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}
</style>
