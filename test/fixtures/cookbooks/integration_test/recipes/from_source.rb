wordpress 'wp_main' do
  path '/opt/wordpress'
  keys_auth         'qZfq*anWbNq `5q}O|J+eJkBs-a@%@CBn2 .%Ku`.X+G;|![V~BAz,g}KW5f90-@'
  keys_secure_auth  '&0j7f~*0}$9,JNd?3E-83ML4dE@+_UQ-^=/#g.NsCLvw_s}n6q##.1n[^O3EZ(}k'
  keys_logged_in    'HywyJ?VQ%ts%-/T* NL3Ldx4yz>RUepw.a2}*|kijQZ:OG@[^f[D-%f:%RE:%e0o'
  keys_nonce        '!5p>5ukJcxsm]&4<O[0QrpIKW ZB4np.#KPB)lYP{Z1PY|y}NG|#7VHV-UhEcu55'
  salt_auth         '{)O|HUB.*:@i;Z5rt}(O2u~C^Q ^]?9J&Xl`/E6*` 01db-yb_D{CWJ]5ooa]R<&'
  salt_secure_auth  'Av11^S?/LuC8f;$TxsIY-|HZz0|pYfaiMVY#usj^NxWWrOZ~T^.k[/sHi|yu=9XP'
  salt_logged_in    'f^AOI7$b%g(lYx-A(~!K2zRuD1^)62Za$e`+]?EV(CaK4COh}?6/>m%+OafL[p@X'
  salt_nonce        'I*:mMrkn/,.km~O?mI+[Hv+479Gj(,_[90A_-<<s?F&[9|Qwv$-2+NL*sJd+|~*k'
  db_password       'wp_1pass'
end
