// JobMaker: import things from FC6 funcs

// itype: 1=ROC, 2=SO
boolean impFC6_SOROC_items(String ivn, String ijob, int itype)
{
	kk = kiboo.replaceSingleQuotes( ivn.trim() );
	if(kk.equals("")) return false;

	vtype = "5635"; // ROC
	switch(itype)
	{
		case 2:
			vtype = "5632";
			break;
	}

	sqlstm = "select ro.name as product_name, u.spec1yh, u.spec2yh, iy.gross,iy.stockvalue, cast((iy.quantity*-1) as int) as unitqty, iy.rate as perunit, " +
	"iy.input1 as rentperiod, iy.output2 as mthtotal from data d " +
	"left join mr008 ro on ro.masterid = d.tags6 left join indta iy on iy.salesid = d.salesoff " +
	"left join u011b u on u.extraid = d.extraoff " +
	"where d.vouchertype=" + vtype + " and d.voucherno='" + kk + "' order by d.bodyid";

	trs = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(trs.size() == 0) return false;

	itms = qtys = rperiod = rpunit = colors = "";

	for(d : trs)
	{
		itms += kiboo.checkNullString(d.get("product_name")).trim() + "\n" +
		kiboo.checkNullString(d.get("spec1yh")).trim() + "\n" +
		kiboo.checkNullString(d.get("spec2yh")).trim() + "::";
		qtys += d.get("unitqty").toString() + "::";
		rperiod += d.get("rentperiod").toString() + "::";
		rpunit += d.get("perunit").toString() + "::";
	}

	sqlstm = "update rw_jobs set items='" + itms + "', qtys='" + qtys + "', rental_periods='" + 
	rperiod + "', rent_perunits='" + rpunit + "', colors='' where origid=" + ijob;

	sqlhand.gpSqlExecuter(sqlstm);
	return true;
}

// itype: 1=ROC, 2=SO
// 17/07/2014: prob with eta/etd, need to put some checks and modifs
boolean impFC6_SOROC_record(String ivn, String ijob, int itype)
{
	kk = kiboo.replaceSingleQuotes( ivn.trim() );
	if(kk.equals("")) return false;

	vtype = "5635"; // ROC
	switch(itype)
	{
		case 2:
			vtype = "5632";
			break;
	}

	sqlstm = "select distinct d.voucherno, d.bookno, " +
	"ac.name as customer_name, aci.telyh, aci.contactyh, aci.emailyh, li.customerrefyh, li.opsnoteyh as deliverynotes, " +
	"li.remarksyh, li.ordertypeyh, li.deliverytoyh, " +
	"case li.etdyh when 0 then null else convert(datetime, dbo.ConvertFocusDate(li.etdyh), 112) end as etd, " +
	"case li.etayh when 0 then null else convert(datetime, dbo.ConvertFocusDate(li.etayh), 112) end as eta " +
	"from data d left join mr000 ac on ac.masterid = d.bookno " +
	"left join u0000 aci on aci.extraid=ac.masterid " +
	"left join u001b li on li.extraid = d.extraheaderoff " +
	"left join header hh on hh.headerid = d.headeroff " +
	"where d.vouchertype=" + vtype + " and d.voucherno='" + kk + "'";

	r = sqlhand.rws_gpSqlFirstRow(sqlstm);
	if(r == null) return false;

	etastr = (r.get("eta") == null) ? "eta=''," : ("eta='" + r.get("eta") + "',");
	etdstr = (r.get("etd") == null) ? "etd=''," : ("etd='" + r.get("etd") + "',");

	sqlstm = "update rw_jobs set rwroc='" + r.get("voucherno") + "', fc6_custid=" + r.get("bookno").toString() + ", customer_name='" + r.get("customer_name") + "'," +
	"notes='" + r.get("deliverynotes") + "\n" + r.get("remarksyh") + "\n" + r.get("ordertypeyh") + "', deliver_address='" + r.get("deliverytoyh") + "'," +
	etastr + etdstr +
	"contact='" + kiboo.checkNullString(r.get("contactyh")) + "'," +
	"contact_tel='" + kiboo.checkNullString(r.get("telyh")) + "'," +
	"contact_email='" + kiboo.checkNullString(r.get("emailyh")) + "', cust_ref='" + r.get("customerrefyh") + "' where origid=" + ijob;

	sqlhand.gpSqlExecuter(sqlstm);
	return true;
}

void impFC6_SOROC(int itype, Object itb)
{
	if(glob_sel_job.equals("")) return;
	kk = itb.getValue();
	errmsg = "ERR: cannot import data from Focus6";

	if(impFC6_SOROC_record(kk, glob_sel_job, itype)) // can import fc6.voucher -- continue import items
	{
		if(!impFC6_SOROC_items(kk, glob_sel_job, itype))
		{
			guihand.showMessageBox(errmsg);
		}
	}
	else
		guihand.showMessageBox(errmsg);

	showJobs();
	showJobMetadata(glob_sel_job);
}

