"""Loyalty tiers for regular clients (LOGIC-009)."""

from __future__ import annotations

from typing import Literal

LoyaltyTier = Literal["regular", "vip"]

LOYALTY_REGULAR_THRESHOLD = 3
LOYALTY_VIP_THRESHOLD = 8
LOYALTY_REGULAR_DISCOUNT_PERCENT = 10
LOYALTY_VIP_DISCOUNT_PERCENT = 15


def loyalty_from_completed_rides(count: int) -> tuple[LoyaltyTier | None, int | None]:
    if count >= LOYALTY_VIP_THRESHOLD:
        return "vip", LOYALTY_VIP_DISCOUNT_PERCENT
    if count >= LOYALTY_REGULAR_THRESHOLD:
        return "regular", LOYALTY_REGULAR_DISCOUNT_PERCENT
    return None, None


def apply_loyalty_discount(amount: int, discount_percent: int | None) -> int:
    if not discount_percent or discount_percent <= 0:
        return amount
    return amount * (100 - discount_percent) // 100
