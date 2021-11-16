# 1. Import the libraries
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# 2. Load the Training Dataset
# Just predicting the "Open Stock Price" for Google. So extracting 1 column.
dataset_train = pd.read_csv('data/Google_Stock_Price_Train.csv')
dataset_train.head()

# 3. Use the Open Stock Price Column to Train Your Model.
# To convert the Vector form of a single column into a Matrix form, we will use 1:2 as the column index. 
# The 2nd column will be ignored and we will get our Open Stock Price Column in a Matrix form.
# Output will be a 2d Numpy array, exactly what we want.
training_set = dataset_train.iloc[:,1:2].values

print(training_set)
print(training_set.shape)

# 4. Normalizing the Dataset
# Default range for MinMaxScaler is 0 to 1, which is what we want. So no arguments in it.
# Will fit the training set to it and get it scaled and replace the original set.
from sklearn.preprocessing import MinMaxScaler
scaler = MinMaxScaler(feature_range = (0,1))
scaled_training_set = scaler.fit_transform(training_set)

scaled_training_set

# 5. Getting the inputs and the ouputs
# Restricting the input and output based on how LSTM functions.
X_train = []
y_train = []
for i in range(60, 1258):
    X_train.append(scaled_training_set[i-60:i, 0])
    y_train.append(scaled_training_set[i, 0])
X_train = np.array(X_train)
y_train = np.array(y_train)

# 6. Reshaping - Adding time interval as a dimension for input.
X_train = np.reshape(X_train, (X_train.shape[0], X_train.shape[1], 1))

# Part 2 - Building the Model

# 7. Importing the Keras libraries and packages
from keras.models import Sequential
from keras.layers import LSTM
from keras.layers import Dense
from keras.layers import Dropout


regressor = Sequential()

# Adding the input layer and the LSTM layer
regressor.add(LSTM(units = 50, return_sequences= True, input_shape = (X_train.shape[1], 1)))
regressor.add(Dropout(0.2))

regressor.add(LSTM(units = 50, return_sequences= True))
regressor.add(Dropout(0.2))

regressor.add(LSTM(units = 50, return_sequences= True))
regressor.add(Dropout(0.2))

regressor.add(LSTM(units = 50))
regressor.add(Dropout(0.2))

regressor.add(Dense(units=1))

# 8. Fitting the model
regressor.compile(optimizer = 'adam', loss = 'mean_squared_error')
regressor.fit(X_train, y_train, epochs=100, batch_size=32)

# 9. Extracting the Actual Stock Prices of Jan-2017
dataset_test = pd.read_csv("data/Google_Stock_Price_Test.csv")
actual_stock_price = dataset_test.iloc[:,1:2].values

# 10. Preparing the Input for the Model
dataset_total = pd.concat((dataset_train['Open'], dataset_test['Open']), axis = 0)
inputs = dataset_total[len(dataset_total)- len(dataset_test)-60:].values

inputs = inputs.reshape(-1,1)
inputs = scaler.transform(inputs)

X_test = []
for i in range(60, 80):
    X_test.append(inputs[i-60:i, 0])
X_test = np.array(X_test)
X_test = np.reshape(X_test,(X_test.shape[0], X_test.shape[1], 1))

# 11. Predicting the Values for Jan 2017 Stock Prices
predicted_stock_price = regressor.predict(X_test)
predicted_stock_price = scaler.inverse_transform(predicted_stock_price)

plt.plot(actual_stock_price, color='red', label='Actual Google Stock Price')
plt.plot(predicted_stock_price, color='blue', label='Predicted Google Stock Price')
plt.title('Google Stock Price Prediction')
plt.xlabel('Time')
plt.ylabel('Google Stock Price')
plt.legend()







