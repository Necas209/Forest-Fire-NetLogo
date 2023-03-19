from dataclasses import dataclass
from pathlib import Path
from typing import Self

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


@dataclass
class Run:
    tick: np.ndarray[int]
    forest_burnt: np.ndarray[int]
    forest_burnt_perc: np.ndarray[float]
    oak_trees_burnt: np.ndarray[int]
    pine_trees_burnt: np.ndarray[int]
    no_sparks: np.ndarray[int]
    mean_temperature: np.ndarray[float]
    max_temperature: np.ndarray[float]

    @classmethod
    def from_csv(cls, path: Path) -> Self:
        """
        Load a run from a csv file.
        :param path: Path to the csv file.
        :return: The run.
        """
        df = pd.read_csv(path)
        return cls(**dict(zip(df.columns, df.to_numpy().T)))

    def extend(self, no_ticks: int) -> None:
        """
        Extend the run with the given number of ticks.
        :param no_ticks: Number of ticks to extend the run with.
        :return: None
        """
        no_ticks = int(no_ticks)
        self.tick = np.append(self.tick, np.arange(self.tick[-1] + 1, self.tick[-1] + no_ticks + 1))
        keys = [key for key in self.__dict__.keys() if key != "tick"]
        for key in keys:
            self.__dict__[key] = np.append(
                self.__dict__[key],
                np.full(no_ticks, self.__dict__[key][-1])
            )

    def plot_metrics(self, save_path: Path | None = None) -> None:
        """
        Plot all metrics. This is a convenience function.
        :param save_path: The path where to save the plots. If None, the plots are shown.
        :return: None
        """
        self.plot_forest_burnt(save_path)
        self.plot_trees_burnt(save_path)
        self.plot_sparks(save_path)
        self.plot_temperature(save_path)

    def plot_forest_burnt(self, save_path: Path | None = None) -> None:
        """
        Plot the forest burnt over time.
        :param save_path: The path where to save the plot. If None, the plot is shown.
        :return: None
        """
        plt.plot(self.tick, self.forest_burnt_perc, label="Forest burnt (%)")
        plt.title("Forest fire")
        plt.legend()
        if save_path is not None:
            plt.savefig(save_path / "forest_fire.png")
            plt.close()
        else:
            plt.show()

    def plot_trees_burnt(self, save_path: Path | None = None) -> None:
        """
        Plot the number of trees burnt over time. This includes oak and pine trees.
        :param save_path: The path where to save the plot. If None, the plot is shown.
        :return: None
        """
        plt.plot(self.tick, self.forest_burnt, label="Trees burnt")
        plt.plot(self.tick, self.oak_trees_burnt, label="Oak trees burnt")
        plt.plot(self.tick, self.pine_trees_burnt, label="Pine trees burnt")
        plt.title("Trees burnt")
        plt.legend()
        if save_path is not None:
            plt.savefig(save_path / "trees_burnt.png")
            plt.close()
        else:
            plt.show()

    def plot_temperature(self, save_path: Path | None = None) -> None:
        """
        Plot the temperature over time. This includes the mean and max temperature.
        :param save_path: The path where to save the plot. If None, the plot is shown.
        :return: None
        """
        plt.plot(self.tick, self.mean_temperature, label="Mean temperature")
        plt.plot(self.tick, self.max_temperature, label="Max temperature")
        plt.title("Forest temperature")
        plt.legend()
        if save_path is not None:
            plt.savefig(save_path / "temperature.png")
            plt.close()
        else:
            plt.show()

    def plot_sparks(self, save_path: Path | None = None) -> None:
        """
        Plot the number of sparks over time.
        :param save_path: The path where to save the plot. If None, the plot is shown.
        :return: None
        """
        plt.plot(self.tick, self.no_sparks, label="Number of sparks")
        plt.title("Number of sparks")
        plt.legend()
        if save_path is not None:
            plt.savefig(save_path / "sparks.png")
            plt.close()
        else:
            plt.show()

    def to_csv(self, path: Path) -> None:
        """
        Save the run to a csv file.
        :param path: Path to the csv file.
        :return: None
        """
        df = pd.DataFrame(self.__dict__)
        df.to_csv(path, index=False)
