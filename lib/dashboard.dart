import 'package:flutter/material.dart';
import 'api.dart';
import 'util.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> {
  Map? d;
  String? err;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await Api.get('dashboard');
      if (mounted) setState(() {
        d = r as Map;
        err = null;
      });
    } catch (e) {
      if (mounted) setState(() => err = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (d == null) return Center(child: err != null ? Padding(padding: const EdgeInsets.all(20), child: Text(err!)) : const CircularProgressIndicator());
    final s = d!['S'] as Map;
    final months = (d!['months'] as List);
    final mx = months.fold<num>(1, (a, m) => [a, numOf(m['invoiced']), numOf(m['received'])].reduce((x, y) => x > y ? x : y));
    const ml = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            Stat('Total sales (excl. GST)', inr(s['sales'])),
            Stat('Invoiced (incl. GST)', inr(s['invoiced'])),
            Stat('Received', inr(s['received'])),
            Stat('Outstanding', inr(s['outstanding'])),
            Stat('Overdue (${s['overdue_n']})', inr(s['overdue'])),
            Stat('Expenses', inr(s['expenses'])),
            Stat('Est. profit', inr(s['profit'])),
            Stat('Customers / Deals', '${s['customers']} / ${s['deals']}'),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly ${d!['year']}', style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
            const Text('gold = invoiced · green = received', style: TextStyle(fontSize: 11, color: Color(0xFF6B7690))),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 6, height: 120 * numOf(months[i]['invoiced']) / mx, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 2),
                        Container(width: 6, height: 120 * numOf(months[i]['received']) / mx, decoration: BoxDecoration(color: okGreen, borderRadius: BorderRadius.circular(3))),
                      ]),
                      const SizedBox(height: 4),
                      Text(ml[i], style: const TextStyle(fontSize: 10, color: Color(0xFF6B7690))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sales by category', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 8),
            if ((d!['cats'] as List).isEmpty) const Text('No invoices yet'),
            for (final c in (d!['cats'] as List).take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${c[0]}'), Text(inr(c[1]), style: const TextStyle(fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 3),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (numOf(c[1]) / (numOf((d!['cats'] as List)[0][1]) == 0 ? 1 : numOf((d!['cats'] as List)[0][1]))).clamp(0, 1).toDouble(), minHeight: 6, color: gold, backgroundColor: const Color(0xFFEEF1F8))),
                ]),
              ),
          ]),
        ),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent payments', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
            if ((d!['recent'] as List).isEmpty) const Padding(padding: EdgeInsets.only(top: 6), child: Text('No payments yet')),
            for (final p in (d!['recent'] as List))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${p['cname'] ?? ''}'),
                subtitle: Text('${p['date']} · ${p['number']}'),
                trailing: Text('${p['kind'] == 'refund' ? '- ' : ''}${inr(p['amount'])}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ]),
    );
  }
}
