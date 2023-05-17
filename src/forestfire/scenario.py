from dataclasses import dataclass, field
from pathlib import Path
from typing import Self

import numpy as np
import yaml

from forestfire.run import Run


@dataclass
class Scenario:
    forest_density: int
    inclination: int
    spread_probability: int
    east_wind_speed: int
    north_wind_speed: int
    initial_temperature: int
    no_trees: int
    no_oak_trees: int
    no_pine_trees: int
    runs: list[Run] = field(default_factory=list)

    @classmethod
    def from_yaml(cls, path: Path) -> Self:
        """
        Load a scenario from a folder containing a config.yaml file and csv files for each run.
        :param path: Path to the folder.
        :return: The scenario.
        """
        config_path = path / "config.yaml"
        with open(config_path, "r") as f:
            config: dict[str, int] = yaml.safe_load(f)
        runs = [Run.from_csv(path / f"run{i}.csv") for i in range(11)]
        # replace keys with snake case
        config = {k.replace("-", "_"): v for k, v in config.items()}
        return cls(**config, runs=runs)

    def __post_init__(self) -> None:
        self.runs.sort(key=lambda run: run.tick[-1])
        self.extend_runs()

    def extend_runs(self) -> None:
        """
        Extend all runs in the scenario to the same length.
        :return: None
        """
        max_ticks = self.runs[-1].tick[-1]
        for run in self.runs:
            run.extend(max_ticks - run.tick[-1])

    def average_run(self) -> Run:
        """
        Calculate the average run. This is done by averaging the values of each run.
        :return: The average run.
        """
        return Run(
            tick=self.runs[0].tick,
            forest_burnt=np.mean([run.forest_burnt for run in self.runs], axis=0),
            forest_burnt_perc=np.mean([run.forest_burnt_perc for run in self.runs], axis=0),
            oak_trees_burnt=np.mean([run.oak_trees_burnt for run in self.runs], axis=0),
            pine_trees_burnt=np.mean([run.pine_trees_burnt for run in self.runs], axis=0),
            no_sparks=np.mean([run.no_sparks for run in self.runs], axis=0),
            mean_temperature=np.mean([run.mean_temperature for run in self.runs], axis=0),
            max_temperature=np.mean([run.max_temperature for run in self.runs], axis=0),
        )
