#Importing Libraries
library(dplyr, quietly = T)
library(caret, quietly = T)
library(irr, quietly = T)
library(pROC, quietly = T)
library(psych, quietly = T)
library(stargazer, quietly = T)

#Reading the data
library(openintro, quietly = T)
data("resume")

#Storing it in a dataframe called 'base_data'
base_data <- resume
# head(resume)
print(nrow(base_data))
print(ncol(base_data))
#glimpse(base_data)


#Converting factor variables to factors, filling missing data in job_req_min_experience 
resume$job_req_min_experience <- ifelse(resume$job_req_min_experience == "", 0, resume$job_req_min_experience)
resume$job_req_min_experience <- ifelse(resume$job_req_min_experience == "some", 0.5, resume$job_req_min_experience)

resume$gender_factors <- factor(resume$gender, levels = c("m", "f"))
resume$resume_quality_factors <- factor(resume$resume_quality, levels = c("low", "high"))
resume$race_factors <- factor(resume$race, levels = c("black", "white"))
resume$job_equal_opp_employer <- as.factor(resume$job_equal_opp_employer)
resume$job_fed_contractor <- as.factor(resume$job_fed_contractor)
resume$job_req_any <- as.factor(resume$job_req_any)
resume$job_req_communication <- as.factor(resume$job_req_communication)
resume$job_req_education <- as.factor(resume$job_req_education)
resume$job_req_min_experience <- as.factor(resume$job_req_min_experience)
resume$job_req_computer <- as.factor(resume$job_req_computer)
resume$job_req_organization <- as.factor(resume$job_req_organization)
resume$honors <- as.factor(resume$honors)
resume$worked_during_school <- as.factor(resume$worked_during_school)
resume$computer_skills <- as.factor(resume$computer_skills)
resume$special_skills <- as.factor(resume$special_skills)
resume$volunteer <- as.factor(resume$volunteer)
resume$military <- as.factor(resume$military)
resume$employment_holes <- as.factor(resume$employment_holes)
resume$has_email_address <- as.factor(resume$has_email_address)

# Plotting the bar chart
ggplot(resume, aes(x = race, fill = gender_factors)) +
  geom_bar() +
  labs(title = "Fig 2.1: Relationship between Gender and Received Callback", x = "Race", y = "#Calls") +
  theme(legend.position = "bottom")+
  scale_fill_discrete(name = "Gender", labels = c("Male", "Female"))


set.seed(9482)
sample <- sample(c(TRUE, FALSE), nrow(resume), replace=TRUE, prob=c(0.8,0.2))
train <- resume[sample,]
test <- resume[!sample,]

model <- glm(received_callback~
               job_city+
               job_industry+
               job_type+
               job_req_min_experience+
               resume_quality_factors+
               gender_factors+
               race_factors+
               years_college+
               college_degree+
               honors+
               worked_during_school+
               years_experience+
               computer_skills+
               volunteer+
               military+
               employment_holes+
               has_email_address
             , family="binomial", data=resume)
options(scipen=999)
summary(model)

resume$test_results <- predict(model, resume, type = 'response')
#table_mat <- table(resume$received_callback, test_results > 0.2)
#table_mat

#precision <- function(matrix) {
# True positive
#    tp <- matrix[2, 2]
# false positive
#    fp <- matrix[1, 2]
#    return (tp / (tp + fp))
#}
#print(precision(table_mat))
#recall <- function(matrix) {
# true positive
#    tp <- matrix[2, 2]# false positive
#    fn <- matrix[2, 1]
#    return (tp / (tp + fn))
#}
#print(recall(table_mat))


threshold <- 0.2
confusionMatrix(factor(resume$test_results>threshold), factor(resume$received_callback==1), positive="TRUE")
kappa2(resume[c('received_callback', 'test_results')])

# Create a table of coefficients, standard errors, p-values, and confidence intervals
library(stargazer)
coefficients_to_include <- c("predictor1", "predictor2")
stargazer(model, 
          title = "Logistic Regression Results", 
          type = "text",
          float = TRUE
)


# Converting the predicted probabilities to binary predictions
resume$predicted_classes <- factor(ifelse(resume$test_results > 0.15, 1, 0), levels = c(0, 1))
resume$actual_classes <- factor(ifelse(resume$received_callback == 1, 1, 0), levels = c(0, 1))
# Calculating the accuracy
confusion_matrix <- confusionMatrix(factor(resume$predicted_classes), factor(resume$actual_classes), positive = "1")

accuracy <- confusionMatrix(factor(resume$predicted_classes), factor(resume$actual_classes), positive = "1")$overall["Accuracy"]
precision <- confusion_matrix$byClass["Pos Pred Value"]
recall <- confusion_matrix$byClass["Sensitivity"]
acc <- confusion_matrix$byClass["Accuracy"]
ckappa <- cohen.kappa(x=cbind(resume$predicted_classes,resume$actual_classes))[1]

#ckappa[1]
#cohen.kappa(x=cbind(resume$predicted_classes,resume$actual_classes))[1]
print(paste("Accuracy:", round(accuracy, 2)))
print(paste("Precision:", round(precision, 2)))
print(paste("Recall/Sensitivity:", round(recall, 2)))
print(paste("Kappa:", ckappa[1]))


confint(model)



# Calculating the ROC curve
roc_curve <- roc(resume$received_callback, resume$test_results)
# Plotting the ROC curve
plot(roc_curve, main = "Plot 4.1: ROC Curve for GLM Model", print.auc = TRUE)
