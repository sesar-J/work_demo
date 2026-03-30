import axios from "axios";

const api = axios.create({
  baseURL: "http://127.0.0.1:8000/api",
  timeout: 15000,
});

export async function fetchCases() {
  const { data } = await api.get("/cases");
  return data;
}

export async function fetchCaseBySlug(slug) {
  const { data } = await api.get(`/cases/${slug}`);
  return data;
}

export async function triggerManualRebuild() {
  const { data } = await api.post("/sync/rebuild");
  return data;
}

export async function fetchSyncStatus() {
  const { data } = await api.get("/sync/status");
  return data;
}
