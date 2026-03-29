# Step 8: 배포

## 실행

1. 사용자에게 배포 승인 요청:

```
QA 테스트를 통과했습니다. 배포를 진행할까요? (y/n)
```

2. 분기:

```
승인 → Skill(skill="deploy", args="all")
거부 → 배포 스킵
```

완료 후 state.json: `current_step = 9`, `deploy_result = "success" | "skipped"`

다음 스텝: `execute/steps/step9-report.md`
