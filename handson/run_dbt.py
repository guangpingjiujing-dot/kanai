"""
dbt run を Python から呼び出すシンプルなスクリプト
"""
import os
import sys
from pathlib import Path

# dbt の CLI をインポート
from dbt.cli.main import dbtRunner


def main():
    # dbt プロジェクトのディレクトリパス
    project_dir = Path(__file__).parent / "dbt_handson_project"
    
    # プロジェクトディレクトリに移動
    os.chdir(project_dir)
    
    # dbtRunner のインスタンスを作成
    dbt = dbtRunner()
    
    # dbt run を実行
    print(f"dbt プロジェクトディレクトリ: {project_dir}")
    print("dbt run を実行します...")
    
    result = dbt.invoke(["run"])
    
    # 結果を確認
    if result.success:
        print("✓ dbt run が正常に完了しました")
        return 0
    else:
        print("✗ dbt run でエラーが発生しました")
        return 1


if __name__ == "__main__":
    sys.exit(main())
