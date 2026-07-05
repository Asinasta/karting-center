import threading
from uuid import uuid4

from app.contracts.bookings import CreateBookingRequest
from app.errors import ApiError


def _available_slot(backend):
    for slot in backend._slots.values():
        if slot.status == "scheduled" and slot.free_seats > 0 and slot.free_rental_gear > 0:
            return slot
    raise AssertionError("no available slot")


def test_no_overbooking_under_concurrency(backend, clock):
    slot = _available_slot(backend)
    capacity = slot.free_seats  # each thread books exactly one seat
    now = clock.now()

    results: list[str] = []
    lock = threading.Lock()

    def worker(i: int) -> None:
        req = CreateBookingRequest(slot_id=slot.id, seat_gear=["own"])
        try:
            backend.create_booking(uuid4(), req, f"idem-conc-{i}", now)
            outcome = "ok"
        except ApiError as exc:
            outcome = exc.code
        with lock:
            results.append(outcome)

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(capacity + 10)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    successes = results.count("ok")
    assert successes == capacity
    assert slot.free_seats == 0
    assert all(r in ("ok", "slot_full") for r in results)
