<template>
  <header class="site-header">
    <div class="container row">
      <div class="left">
        <div class="brand-wrap">
          <img
            class="brand-logo"
            src="https://res-static.hc-cdn.cn/cloudbu-site/china/zh-cn/wangxue/header/logo.svg"
            alt="华为云"
          />
        </div>
        <nav class="menu primary">
          <a href="#">活动</a>
          <a href="#">产品</a>
          <a href="#">解决方案</a>
          <a href="#">定价</a>
          <a href="#">云商店</a>
          <a href="#">合作伙伴</a>
          <a href="#">开发者</a>
          <a href="#">支持与服务</a>
          <a href="#">了解华为云</a>
        </nav>
      </div>
      <div class="right">
        <div class="icons">
          <button class="icon-btn search-icon" aria-label="搜索"></button>
          <button class="icon-btn service-icon" aria-label="客服">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path
                d="M4 12a8 8 0 0 1 16 0v5a2 2 0 0 1-2 2h-2v-5h2v-2a6 6 0 1 0-12 0v2h2v5H6a2 2 0 0 1-2-2z"
              />
              <path d="M14 18a2 2 0 0 1-2 2H9" />
            </svg>
          </button>
        </div>
        <nav class="menu secondary">
          <a href="#">文档</a>
          <a href="#">备案</a>
          <a href="#">控制台</a>
          <a href="#">登录</a>
          <a href="#" class="register">注册</a>
        </nav>
      </div>
    </div>
  </header>
</template>

<style scoped>
.site-header {
  background: #f2f2f2;
  border-bottom: 1px solid #e5e5e5;
  position: sticky;
  top: 0;
  z-index: 30;
}

.container {
  max-width: 1440px;
  margin: 0 auto;
  padding: 0 28px;
  min-height: 50px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
}

.brand-wrap {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.brand-logo {
  width: 118px;
  max-height: 36px;
  height: auto;
  display: block;
}

.menu {
  display: flex;
  align-items: center;
  gap: 16px;
}

.menu a {
  text-decoration: none;
  color: #2f2f2f;
  font-size: 11px;
  font-weight: 400;
  white-space: nowrap;
}

.primary a {
  color: #2d2d2d;
}

.menu a:hover {
  color: #101010;
}

.left,
.right {
  display: flex;
  align-items: center;
  gap: 18px;
  min-width: 0;
}

.icons {
  display: flex;
  align-items: center;
  gap: 8px;
}

.icon-btn {
  width: 18px;
  height: 18px;
  border: none;
  background: transparent;
  color: #5d636f;
  cursor: pointer;
  padding: 0;
  line-height: 1;
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.icon-btn:hover {
  color: #2b2f38;
}

.search-icon::before {
  content: "";
  position: absolute;
  width: 8px;
  height: 8px;
  border: 1.5px solid currentColor;
  border-radius: 50%;
  left: 2px;
  top: 2px;
}

.search-icon::after {
  content: "";
  position: absolute;
  width: 5px;
  height: 1.5px;
  background: currentColor;
  transform: rotate(45deg);
  right: 1px;
  bottom: 2px;
}

.service-icon svg {
  width: 17px;
  height: 17px;
  stroke: currentColor;
  stroke-width: 1.8;
  fill: none;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.secondary {
  gap: 10px;
}

.register {
  background: #d6000f;
  color: #fff !important;
  border-radius: 12px;
  padding: 5px 11px;
  font-weight: 600;
  line-height: 1;
}

@media (max-width: 1200px) {
  .primary {
    gap: 10px;
  }

  .primary a {
    font-size: 11px;
  }

  .secondary {
    gap: 10px;
  }
}

@media (max-width: 980px) {
  .brand-logo {
    width: 102px;
  }

  .primary a:nth-child(n + 7) {
    display: none;
  }

  .secondary a:nth-child(2) {
    display: none;
  }
}
</style>
