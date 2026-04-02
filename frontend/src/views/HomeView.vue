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

function formatSyncMessage(message, status) {
  if (!message) return "暂无同步记录";
  if (message.includes("manual rebuild; cases=")) {
    const count = message.split("cases=")[1] || "0";
    return `已完成案例内容重建，共 ${count} 个案例。`;
  }
  if (message.includes("rebuilt_cases=")) {
    const count = message.split("rebuilt_cases=")[1] || "0";
    return `已完成案例内容同步，本次更新 ${count} 个案例。`;
  }
  if (message.includes("skip non-dtse repo")) {
    return "已忽略非 DTSE 案例仓的推送事件。";
  }
  if (message.startsWith("skip branch:")) {
    const branch = message.replace("skip branch:", "").trim();
    return `已忽略分支 ${branch} 的推送事件。`;
  }
  if (status === "error" && message === "同步状态获取失败") {
    return "同步状态获取失败，请稍后重试。";
  }
  return message;
}

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
    syncMessage.value = formatSyncMessage(data.message, data.status);
  } catch (e) {
    syncStatus.value = "error";
    syncMessage.value = "同步状态获取失败，请稍后重试。";
  }
}

async function manualSync() {
  syncLoading.value = true;
  try {
    const data = await triggerManualRebuild();
    syncStatus.value = "success";
    syncMessage.value = formatSyncMessage(data.message, "success");
    await loadCases();
  } catch (e) {
    syncStatus.value = "error";
    syncMessage.value = "手动同步失败，请稍后重试。";
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
  <div class="page-container">
    <header class="hero glass-panel">
      <div>
        <p class="hero-tag">Hands-on Practice Center</p>
        <h1>华为云 Hands-on 实践中心</h1>
        <p class="hero-desc">通过精选案例快速上手云上开发、部署与自动化运维。</p>
      </div>
      <div class="hero-stats">
        <div class="stat-item">
          <strong>{{ list.length }}</strong>
          <span>案例数量</span>
        </div>
        <div class="stat-item">
          <strong>{{ syncStatus === "success" ? "正常" : "待确认" }}</strong>
          <span>同步状态</span>
        </div>
      </div>
    </header>

    <main>
      <div class="sync-panel glass-panel">
        <div>
          <h3>案例内容同步</h3>
          <p class="sync-text" :class="`status-${syncStatus}`">{{ syncMessage }}</p>
        </div>
        <button :disabled="syncLoading" @click="manualSync">
          {{ syncLoading ? "同步中..." : "手动同步" }}
        </button>
      </div>

      <p v-if="loading" class="state-text">加载案例中...</p>
      <p v-else-if="error" class="state-text error">{{ error }}</p>
      <div v-else class="grid">
        <CaseCard v-for="item in list" :key="item.slug" :case-item="item" />
      </div>
    </main>
  </div>
</template>

<style scoped>
.hero {
  margin-bottom: 18px;
  padding: 22px;
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.hero h1 {
  margin: 8px 0;
  font-size: 32px;
}

.hero-tag {
  margin: 0;
  color: #2563eb;
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.5px;
}

.hero-desc {
  margin: 0;
  color: #4b5563;
}

.hero-stats {
  display: flex;
  align-items: center;
  gap: 12px;
}

.stat-item {
  min-width: 110px;
  text-align: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 10px 12px;
}

.stat-item strong {
  display: block;
  font-size: 22px;
  color: #0f172a;
}

.stat-item span {
  font-size: 12px;
  color: #64748b;
}

.sync-panel {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
  padding: 16px 18px;
}

.sync-panel h3 {
  margin: 0 0 4px;
}

.sync-panel button {
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  color: #fff;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
}

.sync-panel button:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.sync-text {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

.status-success {
  color: #059669;
}

.status-error {
  color: #dc2626;
}

.grid {
  display: grid;
  gap: 18px;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

.state-text {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 12px 14px;
}

.state-text.error {
  color: #b91c1c;
}
</style>
