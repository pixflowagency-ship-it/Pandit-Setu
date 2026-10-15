import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/utils/booking_date_time_helper.dart';
import 'package:pandit_ssetu/utils/carousel_pooja_mapper.dart';
import 'package:pandit_ssetu/widgets/pooja_detail_modal.dart';

void main() {
  group('TASK 1: Booking Date and Time Integrity Tests', () {
    test('Correctly parses morning time slots into 24-hour hours and minutes', () {
      final slot1 = BookingDateTimeHelper.parseTimeSlot('07:00 AM');
      expect(slot1.hour, equals(7));
      expect(slot1.minute, equals(0));

      final slot2 = BookingDateTimeHelper.parseTimeSlot('09:30 AM');
      expect(slot2.hour, equals(9));
      expect(slot2.minute, equals(30));
    });

    test('Correctly parses evening time slots into 24-hour hours and minutes', () {
      final slot1 = BookingDateTimeHelper.parseTimeSlot('04:00 PM');
      expect(slot1.hour, equals(16));
      expect(slot1.minute, equals(0));

      final slot2 = BookingDateTimeHelper.parseTimeSlot('06:30 PM');
      expect(slot2.hour, equals(18));
      expect(slot2.minute, equals(30));
    });

    test('Correctly handles boundary hours 12:00 PM (noon) and 12:00 AM (midnight)', () {
      final noon = BookingDateTimeHelper.parseTimeSlot('12:00 PM');
      expect(noon.hour, equals(12));
      expect(noon.minute, equals(0));

      final midnight = BookingDateTimeHelper.parseTimeSlot('12:00 AM');
      expect(midnight.hour, equals(0));
      expect(midnight.minute, equals(0));
    });

    test('Preserves user wall-clock date and time when converting to UTC ISO 8601', () {
      final testDate = DateTime(2026, 10, 15);
      final isoString = BookingDateTimeHelper.formatToIsoUtc(
        date: testDate,
        timeSlot: '09:30 AM',
      );

      expect(isoString, isNotEmpty);
      expect(isoString.endsWith('Z'), isTrue);

      // When parsed back to local time, it must match 2026-10-15 09:30:00 local!
      final parsedLocal = DateTime.parse(isoString).toLocal();
      expect(parsedLocal.year, equals(2026));
      expect(parsedLocal.month, equals(10));
      expect(parsedLocal.day, equals(15));
      expect(parsedLocal.hour, equals(9));
      expect(parsedLocal.minute, equals(30));
    });

    test('Preserves evening ritual time when converting to UTC ISO 8601', () {
      final testDate = DateTime(2026, 11, 20);
      final isoString = BookingDateTimeHelper.formatToIsoUtc(
        date: testDate,
        timeSlot: '06:30 PM',
      );

      final parsedLocal = DateTime.parse(isoString).toLocal();
      expect(parsedLocal.year, equals(2026));
      expect(parsedLocal.month, equals(11));
      expect(parsedLocal.day, equals(20));
      expect(parsedLocal.hour, equals(18));
      expect(parsedLocal.minute, equals(30));
    });

    test('Rejects invalid time slots with descriptive FormatException', () {
      expect(
        () => BookingDateTimeHelper.parseTimeSlot(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BookingDateTimeHelper.parseTimeSlot('invalid'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BookingDateTimeHelper.parseTimeSlot('13:00 AM'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BookingDateTimeHelper.parseTimeSlot('09:65 AM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('resolveBookingTime correctly accepts valid ISO bookingTime without fallback', () {
      final data = {
        'bookingTime': '2026-10-15T09:30:00.000Z',
      };
      final result = BookingDateTimeHelper.resolveBookingTime(data);
      expect(result, equals('2026-10-15T09:30:00.000Z'));
    });

    test('resolveBookingTime correctly converts date and timeSlot into UTC ISO string', () {
      final data = {
        'date': '15/10/2026',
        'timeSlot': '09:30 AM',
      };
      final result = BookingDateTimeHelper.resolveBookingTime(data);
      expect(result.endsWith('Z'), isTrue);

      final parsedLocal = DateTime.parse(result).toLocal();
      expect(parsedLocal.year, equals(2026));
      expect(parsedLocal.month, equals(10));
      expect(parsedLocal.day, equals(15));
      expect(parsedLocal.hour, equals(9));
      expect(parsedLocal.minute, equals(30));
    });

    test('resolveBookingTime rejects missing date and time selection without silent fallback', () {
      final emptyData = <String, dynamic>{};
      expect(
        () => BookingDateTimeHelper.resolveBookingTime(emptyData),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TASK 2: Home Carousel Pooja Identifiers Tests', () {
    final mockAvailablePoojas = [
      const PoojaDetail(
        id: '67e77a47-8ffb-403a-bc64-c948ab5e2abc',
        title: 'Navratri Pooja',
        category: 'Festival Special Pooja',
        imageUrl: '',
        duration: '9 Days',
        durationBreakdown: '',
        description: '',
        spiritualSignificance: '',
        inclusions: [],
        chantingDetails: [],
        standardPrice: 21000.0,
        samagriPrice: 5250.0,
        originalPrice: 31500.0,
      ),
      const PoojaDetail(
        id: '92086a65-41a9-4545-9588-6f35c8bb8b6b',
        title: 'Satyanarayan Katha',
        category: 'Ghar & Jeevan',
        imageUrl: '',
        duration: '1-3 Hour',
        durationBreakdown: '',
        description: '',
        spiritualSignificance: '',
        inclusions: [],
        chantingDetails: [],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
      ),
      const PoojaDetail(
        id: '9ae802b2-95f9-4461-af5a-e7c32d6fb1af',
        title: 'Griha Pravesh Pooja',
        category: 'Ghar & Jeevan',
        imageUrl: '',
        duration: '1-3 Hour',
        durationBreakdown: '',
        description: '',
        spiritualSignificance: '',
        inclusions: [],
        chantingDetails: [],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
      ),
      const PoojaDetail(
        id: '9484cd34-05de-4b00-9621-b190d075be33',
        title: 'Mahamrityunjaya Jaap',
        category: 'Dosh Nivaran',
        imageUrl: '',
        duration: '1-3 Hour',
        durationBreakdown: '',
        description: '',
        spiritualSignificance: '',
        inclusions: [],
        chantingDetails: [],
        standardPrice: 11000.0,
        samagriPrice: 2750.0,
        originalPrice: 16500.0,
      ),
    ];

    test('Maps carousel slide by verified UUID directly', () {
      final slide = {
        'title': 'Grand Navratri & Durga Puja 2026',
        'poojaId': '67e77a47-8ffb-403a-bc64-c948ab5e2abc',
      };
      final match = CarouselPoojaMapper.findPoojaForSlide(slide, mockAvailablePoojas);
      expect(match, isNotNull);
      expect(match!.id, equals('67e77a47-8ffb-403a-bc64-c948ab5e2abc'));
      expect(match.title, equals('Navratri Pooja'));
    });

    test('Maps legacy slug navratri_pooja to genuine UUID', () {
      final legacySlide = {
        'title': 'Grand Navratri 2026',
        'poojaId': 'navratri_pooja',
      };
      final match = CarouselPoojaMapper.findPoojaForSlide(legacySlide, mockAvailablePoojas);
      expect(match, isNotNull);
      expect(match!.id, equals('67e77a47-8ffb-403a-bc64-c948ab5e2abc'));
    });

    test('Maps legacy slug satyanarayan_katha to genuine UUID', () {
      final legacySlide = {
        'title': 'Shri Satyanarayan Vrat Katha',
        'poojaId': 'satyanarayan_katha',
      };
      final match = CarouselPoojaMapper.findPoojaForSlide(legacySlide, mockAvailablePoojas);
      expect(match, isNotNull);
      expect(match!.id, equals('92086a65-41a9-4545-9588-6f35c8bb8b6b'));
    });

    test('Safely returns null for unmapped carousel entry without defaulting to wrong ritual', () {
      final unmappedSlide = {
        'title': 'Special Solar Eclipse Yajna',
        'poojaId': 'unknown_solar_eclipse_yajna',
      };
      final match = CarouselPoojaMapper.findPoojaForSlide(unmappedSlide, mockAvailablePoojas);
      // MUST NOT fall back to mockAvailablePoojas[0] (Navratri Pooja)!
      expect(match, isNull);
    });
  });
}
