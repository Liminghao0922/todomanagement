#!/usr/bin/env python3
"""
FastAPI API 目录清理脚本
删除 Python 缓存和不需要的文件
"""

import os
import shutil
from pathlib import Path

def cleanup_api_directory():
    """清理 API 目录中的不必要文件和缓存"""
    
    api_path = Path.cwd()
    
    # 要删除的目录
    dirs_to_delete = [
        "__pycache__",
        ".pytest_cache",
        "*.egg-info"
    ]
    
    # 要删除的文件模式
    files_to_delete = [
        "*.pyc",
        "*.pyo",
        "*.pyd",
        ".Python",
        "*.so"
    ]
    
    print("🧹 FastAPI API 目录清理...")
    print("")
    
    # 删除目录
    for dir_name in dirs_to_delete:
        dir_path = api_path / dir_name
        if dir_path.exists() and dir_path.is_dir():
            try:
                print(f"  ❌ 删除: {dir_name}")
                shutil.rmtree(dir_path)
                print(f"     ✓ 已删除")
            except Exception as e:
                print(f"     ⚠️  删除失败: {e}")
    
    # 删除缓存文件
    print("")
    cache_files_deleted = 0
    for pattern in files_to_delete:
        for file_path in api_path.rglob(pattern):
            if file_path.is_file():
                try:
                    file_path.unlink()
                    cache_files_deleted += 1
                except Exception as e:
                    print(f"  ⚠️  无法删除 {file_path}: {e}")
    
    if cache_files_deleted > 0:
        print(f"  ❌ 删除 {cache_files_deleted} 个缓存文件")
        print(f"     ✓ 已删除")
    
    print("")
    print("✅ 清理完成！")
    print("")
    print("📁 保留的关键文件:")
    print("  ✓ config.py          (配置管理)")
    print("  ✓ database.py        (SQLAlchemy 连接)")
    print("  ✓ models.py          (ORM 模型)")
    print("  ✓ schemas.py         (Pydantic 模式)")
    print("  ✓ main.py            (FastAPI 应用)")
    print("  ✓ requirements.txt   (Python 依赖)")
    print("  ✓ .env.local         (环境变量)")
    print("  ✓ Dockerfile         (容器化)")
    print("  ✓ venv/              (虚拟环境)")
    print("")
    print("💡 可选操作:")
    print("  - 删除虚拟环境以节省空间: rm -r venv  (or Remove-Item venv -Recurse)")
    print("  - 本地开发时重建虚拟环境: python -m venv venv")

if __name__ == "__main__":
    cleanup_api_directory()
