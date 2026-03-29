class GetClassesDto {
  final String? status;
  final String? date;
  final String? timeRange;
  final String? category;
  final int? page;
  final int? limit;

  GetClassesDto({
    this.status,
    this.date,
    this.timeRange,
    this.category,
    this.page,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (status != null) data['status'] = status;
    if (date != null) data['date'] = date;
    if (timeRange != null) data['timeRange'] = timeRange;
    if (category != null) data['category'] = category;
    if (page != null) data['page'] = page;
    if (limit != null) data['limit'] = limit;
    
    return data;
  }
}
