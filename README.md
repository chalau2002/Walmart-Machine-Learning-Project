# Walmart-Machine-Learning-Project

Project Theme
The project, developed as part of the Artificial Intelligence Techniques for Forecasting and Optimization in Business Systems course, aimed to create a Decision Support System (DSS) for a Walmart store. The objectives were twofold:

Sales Forecasting: Predicting weekly sales for four departments using time series analysis and machine learning models.
Resource Optimization: Optimizing the allocation of staff and product inventory to maximize profits and minimize operational effort.
This project integrated advanced forecasting and optimization techniques into a functional system with a user-friendly interface, demonstrating the practical application of artificial intelligence in real-world business contexts.

Detailed Work
Forecasting Component

Goals: Develop accurate models to predict weekly sales for each department, leveraging both univariate and multivariate approaches.
Methodology:
Explored methods from the R libraries forecast and rminer.
Applied evaluation techniques such as the growing window to test prediction models.
Incorporated exogenous variables like holidays, fuel prices, and time-based features (week, month) for multivariate forecasts.
Models Implemented:
Univariate: Models such as HoltWinters, Auto.Arima, and LM.
Multivariate: Techniques like AutoVar and VAR with exogenous variables.
Results:
Evaluated models using metrics such as MAE, RMSE, and R².
Determined that univariate models generally outperformed multivariate models.
Optimization Component

Goals: Allocate resources (staff and inventory) to maximize profits (F1) and minimize manual effort (F2).
Methodology:
Developed an evaluation function to calculate costs and profits.
Tested various optimization algorithms:
Uni-objective: Monte Carlo, Hill Climbing, Simulated Annealing, Genetic Algorithm (RGBA), and Tabu Search.
Multi-objective: NSGA-II for Pareto optimization.
Results:
Tabu Search and Genetic Algorithms were identified as the most effective methods for maximizing profits and balancing the trade-offs between objectives.
System Integration

A Shiny-based interface was developed, allowing users to:
Visualize forecasts.
Generate monthly plans for staff and product allocation.
Examine predicted sales, potential profits, and associated costs.

Shiny App demo:
https://www.youtube.com/watch?v=9ZsMoOG8rSw
