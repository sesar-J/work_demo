import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import CaseDetailView from "../views/CaseDetailView.vue";
import CaseLabView from "../views/CaseLabView.vue";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", component: HomeView },
    { path: "/cases/:slug", component: CaseDetailView },
    { path: "/cases/:slug/lab", component: CaseLabView },
  ],
});

export default router;
