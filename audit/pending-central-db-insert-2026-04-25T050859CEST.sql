INSERT INTO iterations (agent,task_id,status,notes) VALUES (
  'sanhedrin',
  'AUDIT',
  'warning',
  'Severity=WARNING heartbeat_within_10min(mod=3s inf=1s san=3s via automation/logs/loop.heartbeat) ps_check_blocked_sandbox(operation_not_permitted) recent_builder_pass_20(mod=20/20 inf=20/20) same_task_streak_ge3(mod=0 inf=0 current=1/1) fail_streak5plus(mod=0 inf=0) builder_outputs_code_files=YES(rows20_code_mod=20 inf=20 law5_mod_hc_sh_last5=5 law5_inf_hc_last5=1 law5_inf_hc_sh_py_last5=11) law1_nonholyc_core_hits=0 law2_network_diff_hits=0 law4_float_hits=111(info) law6_open_cq=41(>=25) secure_local_default_preserved quarantine_hash_guards_present iommu_book_of_truth_gpu_guards_present trinity_policy_parity=ok split_plane_attestation_policy_digest_gates=ok network_enable_paths_not_present ci_check_blocked_no_network(gh_api_unreachable) email_check_blocked_mcp_cancelled(gmail_search_run_failed_newer_than_1h) vm_check_blocked_no_network_ssh(operation_not_permitted) cleanup_old_audit_md_deleted=0 airgap_policy_preserved no_ws8_execution'
);
