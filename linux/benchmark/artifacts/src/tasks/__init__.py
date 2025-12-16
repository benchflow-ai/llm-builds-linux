# Task definitions
from .buildroot_tasks import BUILDROOT_TASKS
from .debootstrap_tasks import DEBOOTSTRAP_TASKS
from .debugging_tasks import DEBUGGING_TASKS

ALL_TASKS = BUILDROOT_TASKS + DEBOOTSTRAP_TASKS + DEBUGGING_TASKS
