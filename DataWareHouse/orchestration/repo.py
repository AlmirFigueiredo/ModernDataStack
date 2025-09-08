import os
import time
import json
import requests
from dagster import Definitions, job, op, get_dagster_logger
from dagster_dbt import DbtCliResource

AIRBYTE_HOST = os.getenv("AIRBYTE_HOST", "host.docker.internal")
AIRBYTE_PORT = int(os.getenv("AIRBYTE_PORT", "8000"))
AIRBYTE_BASE = f"http://{AIRBYTE_HOST}:{AIRBYTE_PORT}"
AIRBYTE_CONNECTION_ID = os.getenv("AIRBYTE_CONNECTION_ID")

@op
def airbyte_sync_op():
    log = get_dagster_logger()
    if not AIRBYTE_CONNECTION_ID:
        raise RuntimeError("AIRBYTE_CONNECTION_ID não definido no ambiente.")

    url_sync = f"{AIRBYTE_BASE}/api/v1/connections/sync"
    log.info(f"Disparando sync no Airbyte: {url_sync} (connectionId={AIRBYTE_CONNECTION_ID})")
    resp = requests.post(url_sync, json={"connectionId": AIRBYTE_CONNECTION_ID}, timeout=30)
    try:
        resp.raise_for_status()
    except Exception as e:
        raise RuntimeError(f"Falha ao chamar Airbyte sync: {e}\nResposta: {resp.text}") from e

    payload = resp.json()

    job_id = None
    if isinstance(payload, dict):

        job_id = payload.get("jobId") or (payload.get("job") or {}).get("id")
    if job_id is None:

        raise RuntimeError(f"Não consegui obter job_id no retorno do Airbyte. Payload: {json.dumps(payload)}")

    log.info(f"Airbyte job_id: {job_id}")


    url_get = f"{AIRBYTE_BASE}/api/v1/jobs/get"
    terminal = {"succeeded", "failed", "cancelled"}
    delay = 3
    max_wait_s = 60 * 20  
    waited = 0

    while True:
        r = requests.post(url_get, json={"id": job_id}, timeout=30)
        try:
            r.raise_for_status()
        except Exception as e:
            raise RuntimeError(f"Falha ao consultar status do job {job_id}: {e}\nResp: {r.text}") from e

        data = r.json()
        status = (data.get("job") or {}).get("status") or data.get("status")
        log.info(f"[Airbyte job {job_id}] status={status}")

        if status and status.lower() in terminal:
            if status.lower() != "succeeded":
                raise RuntimeError(f"Job {job_id} terminou com status={status}")
            log.info(f"Job {job_id} finalizado com sucesso.")
            break

        time.sleep(delay)
        waited += delay
        if waited >= max_wait_s:
            raise TimeoutError(f"Timeout aguardando job {job_id} (>{max_wait_s}s).")

dbt = DbtCliResource(
    project_dir=os.getenv("DBT_PROJECT_DIR", "/usr/app"),
    profiles_dir=os.getenv("DBT_PROFILES_DIR", "/usr/app"),
)

@op
def dbt_build_op():
    for event in dbt.cli(["build"]).stream():
        yield event

@job
def erp_to_gold_job():
    airbyte_sync_op()
    dbt_build_op()

defs = Definitions(jobs=[erp_to_gold_job])
