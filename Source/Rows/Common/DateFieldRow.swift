//  DateFieldRow.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs SRL ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

public protocol DatePickerRowProtocol: AnyObject {
    var minimumDate: Date? { get set }
    var maximumDate: Date? { get set }
    var minuteInterval: Int? { get set }
}

open class DateCell: Cell<Date>, CellType {

    public var datePicker: UIDatePicker

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        datePicker = UIDatePicker()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        datePicker = UIDatePicker()
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType =  .none
        datePicker.datePickerMode = datePickerMode()
        datePicker.addTarget(self, action: #selector(DateCell.datePickerValueDidChange(_:)), for: .valueChanged)

        #if swift(>=5.2)
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
        #endif
    }

    deinit {
        datePicker.removeTarget(self, action: nil, for: .allEvents)
    }

    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
    
        if let dateRow = row as? DatePickerRowProtocol {
            var dateToSet: Date
    
            let minDate = dateRow.minimumDate
            let maxDate = dateRow.maximumDate
    
            // Determine the correct date to set in the picker
            if let value = row.value {
                // If row.value is set, validate it within the bounds of minDate and maxDate
                if let min = minDate, value < min {
                    dateToSet = min  // Adjust to minDate if row.value is below the minimum
                } else if let max = maxDate, value > max {
                    dateToSet = max  // Adjust to maxDate if row.value is above the maximum
                } else {
                    dateToSet = value  // Keep row.value as is if it's within bounds
                }
            } else {
                // If row.value is nil, temporarily set the picker to a valid date within the bounds, but do not modify row.value
                dateToSet = minDate ?? maxDate ?? Date()  // Use minDate, maxDate, or fallback to Date()
            }
    
            // Set the datePicker's min and max dates
            datePicker.minimumDate = minDate
            datePicker.maximumDate = maxDate
    
            // Set the picker date without modifying row.value if it's nil
            datePicker.setDate(dateToSet, animated: row is CountDownPickerRow)
    
            // Only update row.value if it was previously set and needs to be adjusted
            if row.value != nil {
                row.value = dateToSet
            }
    
            // Apply the minute interval if provided
            if let minuteIntervalValue = dateRow.minuteInterval {
                datePicker.minuteInterval = minuteIntervalValue
            }
        }
    
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }
    }

    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }

    override open var inputView: UIView? {
        if let v = row.value {
            datePicker.setDate(v, animated:row is CountDownRow)
        }
        return datePicker
    }

    @objc(datePickerValueDidChange:) func datePickerValueDidChange(_ sender: UIDatePicker) {
        row.value = sender.date
        detailTextLabel?.text = row.displayValueFor?(row.value)
    }

    private func datePickerMode() -> UIDatePicker.Mode {
        switch row {
        case is DateRow:
            return .date
        case is TimeRow:
            return .time
        case is DateTimeRow:
            return .dateAndTime
        case is CountDownRow:
            return .countDownTimer
        default:
            return .date
        }
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return canBecomeFirstResponder
    }

    override open var canBecomeFirstResponder: Bool {
        return !row.isDisabled
    }
}

open class _DateFieldRow: Row<DateCell>, DatePickerRowProtocol, NoValueDisplayTextConformance {

    /// The minimum value for this row's UIDatePicker
    open var minimumDate: Date?

    /// The maximum value for this row's UIDatePicker
    open var maximumDate: Date?

    /// The interval between options for this row's UIDatePicker
    open var minuteInterval: Int?

    /// The formatter for the date picked by the user
    open var dateFormatter: DateFormatter?

    open var noValueDisplayText: String? = nil

    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value, let formatter = self.dateFormatter else { return nil }
            return formatter.string(from: val)
        }
    }
}
