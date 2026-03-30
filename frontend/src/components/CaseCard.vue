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
    <h3>{{ caseItem.title }}</h3>
    <p>{{ caseItem.summary }}</p>
    <TinyButton type="primary" @click="goDetail">查看详情</TinyButton>
  </div>
</template>

<style scoped>
.card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.08);
}

.cover {
  width: 100%;
  height: 180px;
  border-radius: 10px;
  object-fit: cover;
  margin-bottom: 12px;
}

h3 {
  margin: 0 0 8px;
}

p {
  color: #4b5563;
  min-height: 42px;
}
</style>
