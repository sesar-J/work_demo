<script setup>
import { useRouter } from "vue-router";
import { TinyButton } from "@opentiny/vue";

const props = defineProps({
  caseItem: {
    type: Object,
    required: true,
  },
});

const router = useRouter();

function goDetail() {
  router.push(`/cases/${props.caseItem.slug}`);
}
</script>

<template>
  <div class="card">
    <img v-if="caseItem.cover_image" class="cover" :src="caseItem.cover_image" :alt="caseItem.title" />
    <div class="meta">热门实践</div>
    <h3>{{ caseItem.title }}</h3>
    <p>{{ caseItem.summary }}</p>
    <TinyButton type="primary" @click="goDetail">查看详情</TinyButton>
  </div>
</template>

<style scoped>
.card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 14px;
  box-shadow: 0 8px 28px rgba(15, 23, 42, 0.08);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 30px rgba(15, 23, 42, 0.12);
}

.cover {
  width: 100%;
  height: 172px;
  border-radius: 10px;
  object-fit: cover;
  margin-bottom: 10px;
}

.meta {
  display: inline-block;
  font-size: 12px;
  color: #2563eb;
  background: #eff6ff;
  border-radius: 999px;
  padding: 4px 8px;
  margin-bottom: 8px;
}

h3 {
  margin: 0 0 6px;
  font-size: 18px;
}

p {
  color: #4b5563;
  min-height: 44px;
  margin: 0 0 12px;
  line-height: 1.5;
}
</style>
