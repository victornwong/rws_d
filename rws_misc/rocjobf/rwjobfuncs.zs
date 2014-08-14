// 27/06/2014: rwJobScheduler funcs

Object getrwJobRec(String iroc)
{
	sqlstm = "select top 1 j.origid, j.priority, j.order_type from rw_jobs j where ltrim(rtrim(j.rwroc))='" + iroc + "' order by j.origid desc";
	return sqlhand.gpSqlFirstRow(sqlstm);
}

String getBOM_byJob(String ijid)
{
	if(ijid.equals("")) return "";
	sqlstm = "select distinct origid from stockrentalitems where job_id=" + ijid;
	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";
	retv = "";
	for(d : r)
	{
		if(d.get("origid") != null) retv += d.get("origid") + ", ";
	}
	try { retv = retv.substring(0,retv.length()-2); } catch (Exception e) {}
	return retv;
}

// itype: 1=ERG, 2=PRG
String getERGPRG_by_roc(String iroc, int itype) // codes chopped from equipRequest_tracker_v1
{
	g_vouchertype = "7946"; // ERG
	g_extratbl = "u0140";

	if(itype == 2)
	{
		g_vouchertype = "7947";
		g_extratbl = "u0141";
	}

	sqlstm = "select d.voucherno from data d left join " + g_extratbl + " ri on ri.extraid = d.extraoff " +
	"left join header hh on hh.headerid = d.headeroff " +
	"where d.vouchertype=" + g_vouchertype + "and ltrim(rtrim(ri.ordernoyh))='" + iroc + "' and ri.requestbyyh<>'' " +
	"and hh.flags<>0x00A0";

	retv = "";
	r = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";

	for(d : r)
	{
		if(d.get("voucherno") != null) retv += d.get("voucherno") + ", ";
	}
	try { retv = retv.substring(0,retv.length()-2); } catch (Exception e) {}
	return retv;
}

String getDO_fromROC(String iroc)
{
	if(iroc.equals("")) return "";
	sqlstm = "select distinct d.voucherno from data d left join u001c k on k.extraid = d.extraheaderoff " +
	"where d.vouchertype=6144 and ltrim(rtrim(k.referenceyh)) = '" + iroc + "';";
	retv = "";
	r = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";
	for(d : r)
	{
		if(d.get("voucherno") != null) retv += d.get("voucherno") + ", ";
	}
	try { retv = retv.substring(0,retv.length()-2); } catch (Exception e) {}
	return retv;
}

String checkDOs_Delivered_byROC(String iroc)
{
	if(iroc.equals("")) return "";
	sqlstm = "select distinct d.voucherno, k.deliverystatusyh from data d left join u001c k on k.extraid = d.extraheaderoff " +
	"where d.vouchertype=6144 and ltrim(rtrim(k.referenceyh)) = '" + iroc + "';";
	retv = "PENDING";
	dcount = 0;
	r = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";
	for(d : r)
	{
		ds = kiboo.checkNullString(d.get("deliverystatusyh"));
		if(ds.equals("DELIVERED")) dcount++;
	}
	if(dcount == r.size()) retv = "DELIVERED";
	return retv;
}

// itype: 1=roc, 2=so
String getInv_fromROC(String iroc, int itype)
{
	if(iroc.equals("")) return "";

	xtbl = "u001b"; // roc extra-tbl
	vtype = "3329";
	snum = " and 'ROC0'+k.rocnoyh = '" + iroc + "'";

	if(itype == 2) // SO
	{
		xtbl = "u0012"; // so extra-tbl
		vtype = "3328";
		sb = iroc.replaceAll("SO0","");
		snum = " and ltrim(rtrim(k.sonoyh)) like '%" + sb + "%' and ltrim(rtrim(k.sonoyh)) not like 'SV%" + sb + "%' ";
		// ( ltrim(rtrim(k.sonoyh))='" + sb + "' or ltrim(rtrim(k.sonoyh))='" + iroc + "') ";
	}

	sqlstm = "select distinct d.voucherno from data d left join " + xtbl + " k on k.extraid = d.extraheaderoff " +
	"where d.vouchertype=" + vtype + snum;
	retv = "";
	r = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";
	for(d : r)
	{
		if(d.get("voucherno") != null) retv += d.get("voucherno") + ", ";
	}
	try { retv = retv.substring(0,retv.length()-2); } catch (Exception e) {}
	return retv;
}

// itype: 1=roc, 2=so
Object getTotal_fromRWISI(String ivn, int itype)
{
	if(ivn.equals("")) return null;
	vtype = (itype == 1) ? "3329" : "3328";
	kk = makeQuotedFromComma(ivn);
	sqlstm = "select cast(sum(d.amount1) as float) as invtotal from data d " +
	"where d.vouchertype=" + vtype + "and d.voucherno in (" + kk + ")";

	return sqlhand.rws_gpSqlFirstRow(sqlstm);
}