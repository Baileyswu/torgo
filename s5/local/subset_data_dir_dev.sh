#!/usr/bin/env bash
#
# Copyright 2017  Brno University of Technology (Author: Karel Vesely);
# Apache 2.0

# This scripts splits 'data' directory into two parts:
# - data set with 90% of utterances
# - another set with 10% of utterances (dev)

percent=10
seed=777
cv_utt_percent= # ignored (compatibility),
. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: $0 [opts] <src-data> <train-data> <cv-data>"
  echo "  --percent N (default 10)"
  exit 1;
fi

set -euo pipefail

src_data=$1
test_data=$2
dev_data=$3

[ ! -r $src_data/text ] && echo "Missing '$src_data/text'. Error!" && exit 1

tmp=$(mktemp -d /tmp/${USER}_XXXXX)

# Select 'percent' utterances randomly,
cat $src_data/text | awk '{ print $1; }' | utils/shuffle_list.pl --srand $seed >$tmp/utts
n_utts=$(wc -l <$tmp/utts)
n_utt_dev=$(perl -e "print int($percent * $n_utts / 100); ")
#
head -n $n_utt_dev $tmp/utts >$tmp/utt_dev
tail -n+$((n_utt_dev+1)) $tmp/utts >$tmp/utt_test

# Sanity checks,
n_utts=$(wc -l <$src_data/spk2utt)
echo "utts, src=$n_utts, trn=$(wc -l <$tmp/utt_test), cv=$(wc -l $tmp/utt_dev)"
overlap=$(join <(sort $tmp/utt_test) <(sort $tmp/utt_dev) | wc -l)
[ $overlap != 0 ] && \
  echo "WARNING, speaker overlap detected!" && \
  join <(sort $tmp/utt_test) <(sort $tmp/utt_dev) | head && \
  echo '...'

# Create new data dirs,
utils/data/subset_data_dir.sh --utt-list $tmp/utt_test $src_data $test_data
utils/data/subset_data_dir.sh --utt-list $tmp/utt_dev $src_data $dev_data

