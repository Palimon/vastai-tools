#Example vast-cli query:

vastai search offers 'gpu_name=RTX_PRO_6000_WS num_gpus=2 verified=true rentable=false' --limit 1 --order gpuCostPerHour --raw

vastai search offers 'gpu_name=RTX_6000Ada num_gpus=2 verified=true rentable=false' --limit 1 --order gpuCostPerHour --raw


vastai search offers -i "machine_id=43738" rentable=true