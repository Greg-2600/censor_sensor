#!/bin/bash

# define the filename containing domain names
site_list_file='site_list.txt'

# define the results log file
result_file='results.txt'


get_http_request() {
	# grab the domain off the stack
	site="$1"

	# build a url
	url="http://$site/"

	# user agent for curl to use
	ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0"

	# wait a max of 2 seconds for a response
	# make the http request and capture header information
	# suppress verbose output
	# follow redirects
	# capture the http response code if successful
	http_res_code=$(curl --max-time 5 --head --silent --location --user-agent "$ua" "$url"|
		grep HTTP|grep 200)

	# check if we received a "good" http repsonse
	if [ "$http_res_code" ]; then
		# if our request was successful
		echo "success $site"
	else
		# if our request failed
		echo "failure $site"
	fi
}


get_report() {
	# number of sites not reachable
	failure_count=$(grep failure ${result_file}|wc -l)

	# number of sites reached
	success_count=$(grep success ${result_file}|wc -l)

	# percentage of reachable to unreachable 
	percent_fail=$(echo "($failure_count / $success_count) * 100"|bc -l|cut -d'.' -f 1)

	# total number of sites to try
	total_count=$(wc -l ${site_list_file}|awk {'print $1'})

	# report output
	echo "#####################################"
	echo "Total sites         : $total_count"
	echo "Successfuly reached : $success_count"
	echo "Failed to reach     : $failure_count"
	echo "Percent failed      : %$percent_fail"
       	echo "Result set          : ${result_file}"
	echo "#####################################"
}


main() {
	# remove last result file if present
	rm -f ${result_file}

	# make our function callable by xargs
	export -f get_http_request

	# randomly order sites from our list
	sort -R ${site_list_file}|

	# process requests through threading, 2 processes max set here
	xargs --max-args=1 -I{} --max-procs=2 bash -c "get_http_request {}" >> ${result_file}

	# paint result summary to the screen
	get_report
}


main
