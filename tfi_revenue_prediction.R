library(Boruta)
library(caret)
library(data.table)
setwd("~/path/to/folder/with/train_test/files")
train <- read.csv("train.csv")
test  <- read.csv("test.csv")

n.train <- nrow(train)

test$revenue <- 1
dat <- rbind(train, test)
rm(train, test)
#Convert date-time vvalue
dat$Open.Date <- as.POSIXlt("01/01/2015", format="%m/%d/%Y") - as.POSIXlt(dat$Open.Date, format="%m/%d/%Y")
dat$Open.Date <- as.numeric(dat$Open.Date / 1000) #Scale for factors

dat$Type <- as.factor(dat$Type)
dat$City.Group<-as.factor(dat$City.Group)

#Log transform of P Variables and Revenue
dat[, paste("P", 1:37, sep="")] <- log(1 +dat[, paste("P", 1:37, sep="")])

dat$revenue <- log(dat$revenue)
#you can uncomment the following 2 lines in order to see most important features 
#important <- Boruta(revenue~., data=dat[1:n.train, ])
#important$finalDecision

# P-n features below choosen with Boruta 
model <- randomForest(revenue~Open.Date+P1+P2+P17+P21+P23+P28, data=dat[1:n.train,])
prediction <- predict(model,dat[-c(1:n.train),])

pDat<-as.data.frame(cbind(seq(0, length(prediction) - 1, by=1), exp(prediction)))
colnames(pDat)<-c("Id","Prediction")
# if you want to delete outliers  uncomment 2 lines below
# submit$Prediction[submit$Prediction>8000000] <- 8000000
# submit$Prediction[submit$Prediction<2000000] <- 2000000
md<-dat[-c(1:n.train),]

predicteddat <- merge(md,pDat,by="Id")
DT <- data.table(predicteddat)
# cluster all records by Open.Date, City, Type and City.Group and assign for each record in cluster mean of cluster elements
DT<-DT[, Mean:=mean(Prediction), by=list(Open.Date, City,City.Group,Type )]

#make final submission
submit2<-as.data.frame(cbind(DT$Id,DT$Mean))
colnames(submit2)<-c("Id","Prediction")
write.csv(submit2,"submission.csv",row.names=FALSE,quote=FALSE)
