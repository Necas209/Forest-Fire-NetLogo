from pathlib import Path

from forestfire.scenario import Scenario


def main() -> None:
    runs_folder = Path("runs")
    # Load all scenarios
    scenarios = [Scenario.from_yaml(path) for path in runs_folder.iterdir()]
    # Save the average run and metrics plots for each scenario
    for i, scenario in enumerate(scenarios, start=1):
        scenario_path = runs_folder / f'scenario{i}'
        # get the average run
        avg_run = scenario.average_run()
        # Save the average run
        avg_run.to_csv(scenario_path / "average.csv")
        # Save the metrics plots
        avg_run.plot_metrics(save_path=scenario_path)


if __name__ == "__main__":
    main()
