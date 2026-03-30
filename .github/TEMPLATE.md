# 🚀 使用此 Template 创建新项目

感谢使用 **{{PROJECT_TITLE}}** Template！

## 下一步

1. ✅ **查看设置指南**  
   打开 [TEMPLATE_SETUP.md](../../TEMPLATE_SETUP.md) 了解如何自定义项目

2. ✅ **自定义项目参数**  
   - 决定项目名称（`{{PROJECT_NAME}}`）
   - 选择 Azure 区域（`{{AZURE_REGION}}`）
   - 选择环境标识（`{{ENVIRONMENT}}`）

3. ✅ **搜索和替换占位符**  
   使用 VS Code 的"查找和替换"功能，或运行提供的脚本

4. ✅ **验证没有遗留占位符**  
   ```bash
   grep -r "{{" . --include="*.md" --include="*.json" --include="*.yml" --include="*.bicep"
   ```

5. ✅ **配置 GitHub Secrets 和 Variables**  
   参考 `docs/GITHUB_CONFIG_SETUP.md`

6. ✅ **运行本地测试**  
   按 `README.md` 的"本地运行"部分进行

7. ✅ **部署到 Azure**  
   按 `README.md` 的"Azure Cloud Shell 部署"进行

## 需要帮助？

- 查看 [TEMPLATE_SETUP.md](../../TEMPLATE_SETUP.md) 常见问题部分
- 查阅 [docs/ARCHITECTURE_GUIDE.md](../../docs/ARCHITECTURE_GUIDE.md)
- 在 GitHub Issues 中报告问题

---

**祝您部署顺利！** 🎉
