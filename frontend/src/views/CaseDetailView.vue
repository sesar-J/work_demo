<script setup>
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { TinyButton } from "@opentiny/vue";
import { fetchCaseBySlug } from "../api";

const route = useRoute();
const router = useRouter();
const loading = ref(false);
const item = ref(null);
const error = ref("");

onMounted(async () => {
  loading.value = true;
  error.value = "";
  try {
    item.value = await fetchCaseBySlug(route.params.slug);
  } catch (e) {
    error.value = "加载详情失败。";
  } finally {
    loading.value = false;
  }
});

function startNow() {
  router.push(`/cases/${route.params.slug}/lab`);
}
</script>

<template>
  <div class="page-container">
    <div class="back-wrap">
      <TinyButton @click="router.push('/')">返回首页</TinyButton>
    </div>
    <p v-if="loading" class="state-text">加载中...</p>
    <p v-else-if="error" class="state-text error">{{ error }}</p>
    <div v-else-if="item" class="detail-wrap">
      <section class="intro glass-panel">
        <h1>{{ item.title }}</h1>
        <p>{{ item.summary }}</p>
        <TinyButton type="primary" @click="startNow">立即开始</TinyButton>
      </section>
      <section class="article glass-panel markdown-content" v-html="item.detail_html"></section>
    </div>
  </div>
</template>

<style scoped>
.back-wrap {
  margin-bottom: 12px;
}

.detail-wrap {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.intro {
  padding: 20px;
}

.intro h1 {
  margin: 0 0 8px;
}

.intro p {
  margin: 0 0 14px;
  color: #4b5563;
  line-height: 1.6;
}

.article {
  padding: 20px;
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
