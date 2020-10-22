#/bin/bash
function traversing () {
  for i in `cat ../domains/${domain}_urls.txt`
  do
    echo ${i} | grep "/*?.*=*" | awk -F '=' '{print $1"="}' | sed 's/\// /g' |  sort -u -k3,3 | sed 's! !/!g'

  done
}
echo ====  Let\'s get the subdomains and all the urls with Tomnomnom\'s waybackurl, httprobe and assetfinder===
echo Feed me a domainn:
read domain

if [ -d "${domain}" ] 
then
    echo "The folder is already present. Appending _1 to folder name" 
    mkdir ${domain}_1
    cd ${domain}_1
else
    echo "Creating folder ${domain}"
    mkdir ${domain}
    cd ${domain}
fi
mkdir domains
cd domains
echo ${domain} | httprobe > ${domain}.txt
for i in `cat ${domain}.txt`
do
  echo $i | waybackurls | tee ${domain}_urls.txt
done
echo === Lets\'s try to traverse directories thanks to J.Haddix and   ===
cd ../;mkdir traversals;cd traversals;
echo Downloading LFI SecList from github.com/daneilmiessler/SecLists
#traversing | tee traversing.txt
grep "/*?.*=*" ../domains/${domain}_urls.txt | awk -F '=' '{print $1"="}' | sed 's/\// /g' |  sort -u -k3,3 | sed 's! !/!g' | tee traversing.txt
for i in `curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Fuzzing/LFI/LFI-Jhaddix.txt`
do
  for j in `cat traversing.txt`
  do
    echo ${i}
    dir_trav_http_code=$(curl -sL -w "%{http_code}" -I "${j}${i}" -o /dev/null)
    echo $dir_trav_http_code; 
    if [[ ${dir_trav_http_code} == "200" ]];then
      echo SUCCESS on ${j} with ${i} >>  dir_traversal.txt
    else
      echo Fail on ${j} >> dir_traversal.txt
    fi
  done
done
echo === And now some Open url testing ===
for i in `cat traversing.txt`
do
  if [[ ${i} == *"%2F"* ]];then
    open_url_http=$(curl -sL -w "%{url_effective}" -I "${i}https%3A%2F%2Fwww.google.com%2F" -o /dev/null)
    if [[ ${open_url_http} == "https://www.google.com" ]];then
      echo SUCCESS for open url in ${j} with ${i} >> open_url.txt
    else
      echo Fail >> open_url.txt
    fi
  elif [[ ${i} != *"%2F"* ]] then
      open_url_http=$(curl -sL -w "%{url_effective}" -I "${i}https%3A%2F%2Fwww.google.com%2F" -o /dev/null)
    if [[ ${open_url_http} == "https://www.google.com" ]];then
      echo SUCCESS for open url in ${j} with ${i} >> open_url.txt
    else
      echo Fail >> open_url.txt
    fi
  fi
done
echo === Collecting js files and then looking for some secrets with Tomnomnom\'s GF ===
cd ../;mkdir js;cd js;
cat ../domains/${domain}_urls.txt | grep "/*.js$"
echo === Domain takeover hunting ===
cd ../domains; 
cat ${domain}.txt | parallel -j50 -q curl -w '%{http_code}\t  %{size_download}\t %{url_effective}\n' -o /dev/null -sk | awk '{if ($1 == "404") print $3}' | tee potential_takeover.txt
for i in `cat potential_takeover.txt`
do
  echo ${i} >> takeovers.txt; host -t CNAME >> takeovers.txt; host -t NS >> takeovers.txt;echo "" >> takeovers.txt; echo "" >> takeovers.txt;
done

