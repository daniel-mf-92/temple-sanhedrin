INSERT INTO iterations (agent,task_id,status,notes) VALUES (
  'sanhedrin',
  'AUDIT',
  'fail',
  'Severity=CRITICAL law7_liveness_violation heartbeat_files_missing=1 loop_log_age_sec(mod=235180 inf=235114 san=188006) restart_attempt_blocked(ssh_localhost_op_not_permitted) law5_mod_hc_sh_last5=5 law5_inf_hc_last5=1 law5_inf_hc_sh_py_last5=22 recent_builder_pass_20(mod=7/7 inf=13/13) recent_builder_code_rows(mod=7/7 inf=13/13) law1_nonholyc_core_hits(mod=0 inf=0) law2_network_diff_hits=0 law4_float_hits=info_present law6_open_cq=51(>=25) secure_local_default_preserved quarantine_hash_iommu_bookoftruth_guards_present trinity_policy_parity=ok split_plane_attestation_digest_gates=ok ci_check_blocked_no_network(gh_api_unreachable) vm_check_blocked_no_network_ssh(op_not_permitted) email_check_blocked_mcp_cancelled airgap_policy_preserved no_ws8_execution central_db_write=blocked_readonly'
);

INSERT INTO violations (law_id,agent,severity,evidence,resolved) VALUES (
  7,
  'sanhedrin',
  'critical',
  'Loop liveness failed: stale logs >10min and restart via ssh localhost blocked by sandbox restrictions.',
  0
);
