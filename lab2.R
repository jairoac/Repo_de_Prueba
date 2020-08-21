#Refrigeradores

## Lectura de datos
d <- read.table('~/R/ADII-3332/datasets/datalab2.txt', header = TRUE)
head(d)
str(d)

## Modelo con interacci�n
modelo <- lm(y ~ x1*x2, data = d)
summary(modelo) # x1:x2 no es significante

## Modelo sin interacci�n
modelo2 <- lm(y ~ x1 + x2, data = d)
summary(modelo2) # aumenta el R2adj y el estad�stico F (mejor modelo que el anterior)

## Intervalos de confianza del 95% para todos los coeficientes del modelo
result <- summary(modelo2) # Guarda el resumen del modelo
all <- coefficients(result) # Saca los coeficientes del resumen (estimado, st error, valor t y Pr(>|t|))
betahat <- all[,1] # Los coeficientes estimados (los betas)
Sbeta <- all[,2] #Los errores estandar de los betas
ll <- betahat - 1.96*Sbeta # Limites inferiores del IC, se usa el estad�sitco 1.96 de la normal porque n>30
ul <- betahat + 1.96*Sbeta # Limites superiores del IC
cbind(ll,betahat,ul) # Une los tres vectores formando una matriz que deja ver los l�mites inferior, central y superior de los IC

## Validaci�n de supuestos

r <- rstudent(modelo2) #residuos estudentizados

par(mfrow = c(2,2), mai = c(0.65,0.65,0.65,0.65)) #Establece la disposici�n de 2x2 gr�ficas en el plot y los m�rgenes

#QQ plot y Shapiro - Wilks
qqnorm(r, las = 1, main = '') #Inserta gr�fica QQ sin t�tulo
mtext('Q-Q plot', side = 3, line = .2) #Agrega el t�tulo, en la parte superior del plot, y con un distanciamiento .2
qqline(r, lty = 2) #Agrega l�nea de QQ con el estilo de guiones
legend('topleft', paste0("p=",round(shapiro.test(r)$p.value, 3)), bty = 'n') #Agrega leyenda en la parte superior
  #del plot, pegando con espacios separados "p=" y el valor p de la prueba shapiro-wilks redondeado a tres decimales
  #sin agregar marco a la leyenda

#gr�fico x1 vs r
plot(d$x1, r, las = 1, ylab = '', xlab = 'x1') #Inserta gr�fica de dispersi�n x1 vs r (las = 1 significa que el texto va siempr ehorizontal)
mtext('r', side = 2, line = 2.5, las = 1) #Agrega "r" al lado izquierdo
abline(h = 0, lty = 2) #Agrega l�nea a la altura del 0, con estilo de guiones
mtext('x1 vs. r', side =3, line = .2, las = 1)

#gr�fico x2 vs r
plot(d$x2, r, las = 1, ylab = "", xlab = 'x2')
mtext("r", side = 2, line = 2.5, las = 1)
abline(h = 0, lty = 2)
mtext("r vs. x2", side = 3, line = .2)

#gr�fico y_gorro vs r
plot(fitted(modelo2), r, las = 1, xlab = expression(hat(y)), ylab = '') #Inserta gr�fica de valores ajustados del modelo vs r
mtext("r", side = 2, line = 2.5, las = 1)
abline(h = 0, lty = 2)
mtext(expression("r vs. "*hat(y)), side = 3, line = .2) #Agrega el t�tulo

#Prueba de homocedasticidad con valor p
car::ncvTest(modelo2) #Valor p 0.582 <- NO rechazar Ho -> S� son homoced�sticos

#Prueba de independencia con ACF
par(mfrow = c(1,1))
acf(r, las = 1, lag.max = 15, main = '') # <- No se sale ninguna barra excepto la primera <- S� son independientes
mtext('ACF', side = 3, line = .2)

#ahora con durbin - watson
durbinWatsonTest(modelo2) # p value = 0.324 <- No rechazar -> Son independientes


## Predicci�n para x1=12, x2=70
predict(modelo2, newdata = data.frame(x1 = 12, x2 = 70), interval = 'prediction')
  #predice con dos nuevos valores de x1 y x2 un nuevo valor para y incluyendo el intervalo de predicci�n


## Rango �ptimo de operaci�n del equipo para que 77 < |E[y]| < 82

# Se utiliza grid-search
f <- with(d, expand.grid(x1 = seq(min(x1), max(x1), length = 20),   #Genera 20 valores (u observaciones artificiales) secuenciados en el rango
  x2 = seq(min(x2), max(x2), length = 20)))  #tanto de x1 como x2 y con ellos genera un dataframe (f) con todas sus combinaciones (es decir, 400 en total)

f$yhat <- apply(f, 1, function(x) sum(c(1, unlist(x))*coefficients(modelo2))) #crea una nueva columna en el dataframe f, donde a cada columna (eso significa el 1)
  #le aplica una funci�n que multiplica el valor de x1 y x2 para cada muestra por el coeficiente que le corresponde en el modelo. El intercepto se debe 
  #multiplicar por 1, ya que se mantiene constante, por eso se concatena un 1 antes de hacer el unlist(x)

lx1 <- length(unique(f$x1)) #Calcula y asigna el valor del n�mero de elementos diferentes en la columna x1 de f (ya se sabe que son 20)
lx2 <- length(unique(f$x2)) #Calcula y asigna el valor del n�mero de elementos diferentes en la columna x2 de f (ya se sabe que son 20)
z <- matrix(f$yhat, ncol = lx2, byrow =TRUE) #Crea una matriz de 20 columnas que se va llenando por filas con los datos de yhat

## curvas de nivel
contour(z, col = 1, labcex = .8, las = 1, xlab = "x1 (100%)", ylab = 'x2 (100%)')
    # Dado que ya se tiene una matriz 20x20, se elabora la gr�fica de curvas de nivel con filas y columnas como coordenadas (x1 y x2 respectivamente)

## Cu�ntas combinaciones cumplen con que 77 < |E[y]| < 82
nrow(subset(f, 77 < yhat & yhat < 82))
    #Se hace una substracci�n del dataframe f de las filas que cumplan con la condici�n y se cuentan las filas de ese substracto

#### IMPORTANTE: A�N NO SABEMOS CUAL DE ESAS 86 COMBINACIONES ES LA M�S APROPIADA, Y AH� 
####            EST�, ENTONCES, EL RETO