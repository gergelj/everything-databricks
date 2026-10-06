"""Write synthetic claim JSON files to the landing volume (dev/staging only)."""

import argparse
import json
import random
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

LINES_OF_BUSINESS = ["motor", "home", "health", "travel", "life"]


def make_claim(rng: random.Random, today: date) -> dict:
    policy_start = today - timedelta(days=rng.randint(1, 1500))
    claim_date = policy_start + timedelta(days=rng.randint(0, (today - policy_start).days))
    claim = {
        "claim_id": str(uuid.UUID(int=rng.getrandbits(128))),
        "policy_id": f"POL-{rng.randint(100000, 999999)}",
        "line_of_business": rng.choice(LINES_OF_BUSINESS),
        "claim_amount_ils": round(rng.lognormvariate(9, 1.2), 2),
        "claim_date": claim_date.isoformat(),
        "policy_start_date": policy_start.isoformat(),
    }
    # A few bad records so the pipeline expectations have something to catch.
    if rng.random() < 0.02:
        claim["policy_id"] = None
    return claim


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--landing-path", required=True)
    parser.add_argument("--num-claims", type=int, default=500)
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    out_dir = Path(args.landing_path)
    out_dir.mkdir(parents=True, exist_ok=True)
    today = datetime.now(ZoneInfo("Asia/Jerusalem")).date()
    out_file = out_dir / f"claims_{uuid.uuid4().hex}.json"
    with out_file.open("w") as f:
        for _ in range(args.num_claims):
            f.write(json.dumps(make_claim(rng, today)) + "\n")
    print(f"Wrote {args.num_claims} claims to {out_file}")
