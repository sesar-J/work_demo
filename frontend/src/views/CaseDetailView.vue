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
  <div class="page">
    <TinyButton @click="router.push('/')">返回首页</TinyButton>
    <p v-if="loading">加载中...</p>
    <p v-else-if="error">{{ error }}</p>
    <div v-else-if="item">
      <h1>{{ item.title }}</h1>
      <p>{{ item.summary }}</p>
      <div class="article" v-html="item.detail_html"></div>
      <TinyButton type="primary" @click="startNow">立即开始</TinyButton>
    </div>
  </div>
</template>

<style scoped>
.page {
  max-width: 960px;
  margin: 0 auto;
  padding: 24px;
}

.article {
  margin: 20px 0;
  padding: 16px;
  border-radius: 12px;
  background: #fff;
}
</style>
