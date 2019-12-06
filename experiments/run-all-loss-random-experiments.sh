########################### All Random Loss Experiments ################################
for i in {1..4}
do
echo "Welcome $i times"
echo "##### STARTED LOSS 1 EXPERIMENTS #####"
./run-loss1-random-experiment.sh
echo "##### STARTED LOSS 2 EXPERIMENTS #####"
./run-loss2-random-experiment.sh
echo "##### STARTED LOSS 4 EXPERIMENTS #####"
./run-loss4-random-experiment.sh
echo "##### STARTED LOSS 8 EXPERIMENTS #####"
./run-loss8-random-experiment.sh
echo "##### STARTED LOSS 16 EXPERIMENTS #####"
./run-loss16-random-experiment.sh
echo "##### COMPLETED ALL EXPERIMENTS #####"
done