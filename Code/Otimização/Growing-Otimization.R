source("functions_Otimization.R")
source("blind.R") # fsearch is defined here
source("montecarlo.R") # mcsearch is defined here
source("hill.R") #  hclimbing is defined here
source("grid.R") #  gsearch is defined here
library(tabuSearch)
library(genalg)
library(adana)

# definir as vendas da semana
actual_sales <- data.frame(
  WSdep1 = c(54480,42221,36267,35283),
  WSdep2 = c(159460,156945,146388,132156),
  WSdep3 = c(63584,62888,62768,60279),
  WSdep4 = c(127009,124560,123346,117375)
)

###################################### DEFINE PARAMETERS ##############################
D = 28
N = 10000 
Ni = 1000 # iterations to get the s0 at montecarlo
N2 = N - Ni # Iteractios to HC and SAN
BEST = 0
EV = 0
curve=rep(NA,N) # vector with the convergence values

# Binary
bits_workers <- 0
bits_orders  <- 0

## Define the eval function
eval_min <- function(s){
  s <- round(s)
  hired_workers = matrix(s[1:12],nrow=3,ncol=4)
  product_orders = matrix(s[13:28],nrow=4,ncol=4)
  sales = calculate_sales(actual_sales,hired_workers, product_orders)
  monthly_profit = sales_in_usd(sales) - total_costs(hired_workers,product_orders, sales)
  
  EV <<- EV + 1
  if(monthly_profit > BEST){
    BEST <<- monthly_profit
  }
  
  if(EV <= N){
    curve[EV] <<- BEST
  }
  
  return(-monthly_profit)
}

eval_max <- function(s){
  s <- round(s)
  hired_workers = matrix(s[1:12],nrow=3,ncol=4)
  product_orders = matrix(s[13:28],nrow=4,ncol=4)
  sales = calculate_sales(actual_sales,hired_workers, product_orders)
  monthly_profit = sales_in_usd(sales) - total_costs(hired_workers,product_orders, sales)
  
  EV <<- EV + 1
  if(monthly_profit > BEST){
    BEST <<- monthly_profit
  }
  
  if(EV <= N){
    curve[EV] <<- BEST
  }
  
  return(monthly_profit)
}


###################################### LOAD DATA #####################################
dados=read.csv("previsoes.csv",header=TRUE,sep=",")

# Selecionar apenas as colunas necessárias
dados_growing <- dados[, c("Departamento1_KSVM", "Departamento2_LM", "Departamento3_MARS", "Departamento4_LM")]
# Dividir os dados em grupos de 4 linhas
grupos <- split(dados_growing, rep(1:8, each = 4))

###################################### MONTECARLO ##############################
montecarlo_growing <- function(){
  montecarlo_values = vector(length = 8)
  
  EV    <<- 0
  BEST  <<- -Inf
  curve <<- rep(NA,N)
  
  # Loop through all the matrices
  for (i in 1:length(grupos)) {
    lower <- rep(0, D) # Lower bounds
    upper <- calculate_uppers(grupos[[i]]) # Upper bounds
    MC    <- mcsearch(fn = eval_max, lower = lower, upper = upper, N = N, type = "max")
    
    montecarlo_values[i] <- eval_max(MC$sol)
  }
  
  plot_iteration_means(curve, N, "Montecarlo",median(montecarlo_values))
  return(median(montecarlo_values))
}

###################################### HILL_CLIMBING ##############################
rchange1 <- function(par, lower, upper) { 
  new_par <- hchange(par, lower = lower, upper = upper, rnorm, mean = 1, sd = 0.20, round = FALSE)
  rounded_par <- ceiling(new_par)
  return(rounded_par)
}

hill_climbing_growing <- function(){
  hill_climbing_values <- vector(length = 8) 
  
  EV <<- 0
  BEST <<- -Inf
  curve <<- rep(NA,N2)
  
  for (i in 1:length(grupos)) {
    lower <- rep(0, D) # limites inferiores
    upper <- calculate_uppers(grupos[[i]])# limites superiores
    actual_sales <- grupos[[i]]
    
    #get s0 from montecarlo with 1000 iteration
    MC <- mcsearch(fn = eval_max, lower = lower, upper = upper, N = Ni, type = "max")
    s0 <- MC$sol
    HC <- hclimbing(par = s0, fn = eval_max, change = rchange1, lower = lower, upper = upper, type = "max",
                    control = list(maxit = N2, REPORT = 0, digits = 2, trace = TRUE))
    hill_climbing_values[i] <- eval_max(HC$sol)
    
  }
  plot_iteration_means(curve, N2, "Hill - Climbing", median(hill_climbing_values))
  return(median(hill_climbing_values))
}


###################################### SIMULATED ANNEALING ##############################
simulatedAnnealing_growing <- function(){
  simulatedAnnealing_values <- vector(length = 8) 
  
  EV    <<- 0
  BEST  <<- -Inf
  curve <<- rep(NA,N2) 
  
  rchange2 <- function(par) {
    new_par     <- hchange(par, lower = lower, upper = upper, rnorm, mean = 1, sd = 0.2, round = FALSE)
    rounded_par <- ceiling(new_par)
    return(rounded_par)
  }
  
  CSANN <- list(maxit = N2, temp = 900, trace = FALSE)
  
  for (i in 1:length(grupos)) {
    lower <- rep(0,D) # limites inferiores
    upper <- calculate_uppers(grupos[[i]])# limites superiores
    actual_sales <- grupos[[i]]
    
    #get s0 from montecarlo with 1000 iteration
    MC <- mcsearch(fn = eval_max, lower = lower, upper = upper, N = Ni, type = "max")
    s0 <- MC$sol
    # Execução do Simulated Annealing
    SA <- optim(par = s0, fn = eval_min, method = "SANN", gr = rchange2, control = CSANN)
    simulatedAnnealing_values[i] <- eval_max(SA$par)
  }
  plot_iteration_means(curve, N2, "Simulated Annealing",median(simulatedAnnealing_values))
  return(median(simulatedAnnealing_values))
}

######################################### RGBA - genetic #########################################
rgba_growing <- function(){
  rgba_values <- vector(length=8) 
  
  
  popSize <- 100
  size    <- 28
  
  EV <<- 0
  BEST <<- -Inf
  curve <<- rep(NA,N/popSize)
  
  
  
  # Loop para percorrer todas as matrizes
  for (i in 1:length(grupos)) {
    lower <- rep(0,D) # limites inferiores
    upper <- calculate_uppers(grupos[[i]])# limites superiores
    actual_sales <- grupos[[i]]
    
    rga <- rbga(stringMin      = lower, 
                stringMax      = upper, 
                popSize        = popSize, 
                mutationChance = 1 / (size + 1), 
                elitism        = popSize * 0.2, 
                evalFunc       = eval_min, 
                iter           = N/popSize)
    
    bs <- rga$population[rga$evaluations == min(rga$evaluations)]
    rgba_values[i] <- eval_max(bs)
  }
  plot_iteration_means(curve, N/popSize, "RBGA Genetic", median(rgba_values))
  return(median(rgba_values))
}


####################################### Tabu - Search ############################################
# Function to divide binary array by bits
matrix_transform <- function(solution, start, elements, dimension_start, bits){
  matrix_final <- c()
  for(i in 1:elements){
    matrix_final[i]  <- bin2int(solution[start:(start + bits - 1)])
    start <- start + bits
  }
  return(matrix_final)
}

# Evaluation Function
eval_bin <- function(solution){
  hired_workers  <- matrix(matrix_transform(solution        = solution,
                                            start           = 1,
                                            elements        = 12,
                                            dimension_start = 1,
                                            bits            = bits_workers), nrow = 3, ncol = 4)
  
  product_orders <- matrix(matrix_transform(solution        = solution,
                                            start           = 12 * bits_workers + 1,
                                            elements        = 16,
                                            dimension_start = 13,
                                            bits            = bits_orders), nrow = 4, ncol = 4)
  
  sales          <- calculate_sales(actual_sales, hired_workers, product_orders)
  monthly_profit <- sales_in_usd(sales) - total_costs(hired_workers, product_orders, sales)
  
  EV <<- EV + 1
  if(monthly_profit > BEST){
    BEST <<- monthly_profit
  }
  
  if(EV <= N){
    curve[EV] <<- BEST
  }
  
  return(monthly_profit)
}

# Function to build Initial Config
initial_config_build <- function(config, n_bits, dimensions){
  initial_length <- length(config)
  while(length(config) - initial_length < dimensions * n_bits){
    config <- c(config, rep(0, n_bits), rep(1, n_bits))
  }
  return(config)
}

tabu_growing <- function(){
  tabu_values <- vector(length=8)
  
  EV <<- 0
  BEST <<- -Inf
  curve <<- rep(NA,N/100) 
  
  for (i in 1:length(grupos)) {
    lower <- rep(0,D) # limites inferiores
    upper <- calculate_uppers(grupos[[i]])# limites superiores
    bits_workers <<- ceiling(max(log(upper[1:12] , 2))) # Bits for Hired Workers
    bits_orders  <<- ceiling(max(log(upper[13:28], 2))) # Bits for Product Orders
    size         <- 12 * bits_workers + 16 * bits_orders # solution size
    
    initial_config <- c() # Building Initial configuration
    initial_config <- initial_config_build(config = initial_config, n_bits = bits_workers, dimensions = 12) # Building Initial configuration for Hired Workers
    initial_config <- initial_config_build(config = initial_config, n_bits = bits_orders , dimensions = 16) # Building Initial configuration for Product Orders
    solution <- tabuSearch(size, iters = N/100, objFunc = eval_bin, config = initial_config, verbose = F)
    
    b  <- which.max(solution$eUtilityKeep) # best index
    bs <- solution$configKeep[b,]
    tabu_values[i] <- eval_bin(bs)
  }
  
  plot_iteration_means(curve, N/100, "Tabu Search Binary", median(tabu_values))
  return(median(tabu_values))
  
}

####################################### RGBA.bin ############################################
eval_bin_min <- function(solution){
  hired_workers  <- matrix(matrix_transform(solution        = solution,
                                            start           = 1,
                                            elements        = 12,
                                            dimension_start = 1,
                                            bits            = bits_workers), nrow = 3, ncol = 4)
  
  product_orders <- matrix(matrix_transform(solution        = solution,
                                            start           = 12 * bits_workers + 1,
                                            elements        = 16,
                                            dimension_start = 13,
                                            bits            = bits_orders), nrow = 4, ncol = 4)
  
  sales          <- calculate_sales(actual_sales, hired_workers, product_orders)
  monthly_profit <- sales_in_usd(sales) - total_costs(hired_workers, product_orders, sales)
  
  EV <<- EV + 1
  if(monthly_profit > BEST){
    BEST <<- monthly_profit
  }
  
  if(EV <= N){
    curve[EV] <<- BEST
  }
  
  return(-monthly_profit)
}


rbga_bin_growing <- function(){
  rbga_bin_values <- vector(length = 8)
  
  popsize <- 100
  
  EV    <<- 0
  BEST  <<- -Inf
  curve <<- rep(NA,N/popsize) 
  
  for(i in 1:length(grupos)) {
    
    # RBGA.bin PARAMETERS
    Low            <- rep(0, D) # Lower
    Up             <- calculate_uppers(grupos[[i]]) # limites superiores 
    bits_workers   <<- ceiling(max(log(Up[1:12] , 2))) # Bits for Hired Workers
    bits_orders    <<- ceiling(max(log(Up[13:28], 2))) # Bits for Product Orders
    size           <- 12 * bits_workers + 16 * bits_orders # solution size
    mutationChance <- 1 / (size + 1)
    elitism        <- popsize * 0.2
    
    rga <- rbga.bin(size           = size,
                    popSize        = popsize,
                    iters          = N/popsize,
                    mutationChance = mutationChance,
                    elitism        = elitism,
                    zeroToOneRatio = 10,
                    evalFunc       = eval_bin_min,
                    verbose        = FALSE)
    
    
    bs <- rga$population[rga$evaluations == min(rga$evaluations)]
    rbga_bin_values[i] <- eval_bin(bs)
  }
  
  plot_iteration_means(curve, N/popsize, "RBGA.bin Binary", median(rbga_bin_values))
  return(median(rbga_bin_values))
}



###################################### PLOT GRAPHIC ##############################
plot_iteration_means <- function(curve, N, name, value) {
  # Calcular a média dos valores de convergência agrupados pelo índice da iteração
  final_means <- numeric(length = N)
  for (j in 1:N) {
    # Extrair os valores correspondentes ao índice da iteração j
    indices <- seq(j, length(curve), N)
    values <- curve[indices]
    final_means[j] <- mean(values, na.rm = TRUE)
  }
  # Plotar o gráfico com as médias dos valores de convergência agrupados pelo índice da iteração
  plot(final_means, type = "l", col = "blue", xlab = "Iteration Index", ylab = "Mean Evaluation Function Value", main = paste("Convergence Curve - ",name, "\n eval: ", value))
}

monte_carlo = montecarlo_growing()
print(paste("Monte Carlo - ", monte_carlo))

hill_climbing = hill_climbing_growing()
print(paste("Hill Climbing - ", hill_climbing))

san = simulatedAnnealing_growing()
print(paste("Simulated Annealing - ", san))

rgba_genetic = rgba_growing()
print(paste("RBGA genetic - ", rgba_genetic))

rgba_bin = rbga_bin_growing()
print(paste("RBGA binary - ", rgba_bin))

tabu = tabu_growing()
print(paste("Tabu - ", tabu))

# Criando um dataframe com os resultados
results <- data.frame(
  MonteCarlo = monte_carlo,
  HillClimbing = hill_climbing,
  SimulatedAnnealing = san,
  RBGAGenetic = rgba_genetic,
  RBGABinary = rgba_bin,
  Tabu = tabu
)

# Exibindo o dataframe
print(results)
