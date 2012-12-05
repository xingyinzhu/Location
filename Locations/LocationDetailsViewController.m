//
//  LocationDetailsViewController.m
//  Locations
//
//  Created by Xingyin Zhu on 12-12-3.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//

#import "LocationDetailsViewController.h"
#import "HudView.h"
#import "Location.h"

@interface LocationDetailsViewController ()

@end

@implementation LocationDetailsViewController
{
    NSString *descriptionText;
    NSString *categoryName;
    NSDate *date;
    UIImage *image;
    UIActionSheet *actionSheet;
    UIImagePickerController *imagePicker;
}

@synthesize managedObjectContext;
@synthesize locationToEdit;

@synthesize imageView;
@synthesize photoLabel;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        descriptionText = @"";
        categoryName = @"No Category";
        date = [NSDate date];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(applicationDidEnterBackground)
            name:UIApplicationDidEnterBackgroundNotification
            object:nil];
    
    }
    return self;
}

- (void)applicationDidEnterBackground
{
    if (imagePicker != nil)
    {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        imagePicker = nil;
    }
    
    if (actionSheet != nil)
    {
        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:NO];
        actionSheet = nil;
    }
    
    [self.descriptionTextView resignFirstResponder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
            name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-  (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark
{
    return [NSString stringWithFormat:@"%@ %@, %@, %@ %@, %@",
            self.placemark.subThoroughfare,
            self.placemark.thoroughfare,
            self.placemark.locality,
            self.placemark.administrativeArea,
            self.placemark.postalCode,
            self.placemark.country];
}

- (NSString *)formatDate:(NSDate *)theDate
{
    static NSDateFormatter *formatter = nil;
    if (formatter == nil)
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return [formatter stringFromDate:theDate];
}

- (void)setLocationToEdit:(Location *)newLocationToEdit
{
    if (locationToEdit != newLocationToEdit)
    {
        locationToEdit = newLocationToEdit;
        descriptionText = locationToEdit.locationDescription;
        categoryName = locationToEdit.category;
        self.coordinate = CLLocationCoordinate2DMake([locationToEdit.latitude doubleValue], [locationToEdit.longitude doubleValue]);
        self.placemark = locationToEdit.placemark;
        date = locationToEdit.date;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.locationToEdit != nil)
    {
        self.title = @"Edit Location";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(done:)];
        if ([self.locationToEdit hasPhoto] && image == nil)
        {
            UIImage *existingImage = [self.locationToEdit photoImage];
            if (existingImage != nil)
            {
                [self showImage:existingImage];
            }
        }
        
        
    }
    
    if (image != nil)
    {
        [self showImage:image];
    }

    self.descriptionTextView.text = descriptionText;
    self.categoryLabel.text = categoryName;
    
    self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", self.coordinate.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", self.coordinate.longitude];
    
    if (self.placemark != nil)
    {
        self.addressLabel.text = [self stringFromPlacemark:self.placemark];
    }
    else
    {
        self.addressLabel.text = @"No Address Found";
    }
    
    self.dateLabel.text = [self formatDate:date];
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
}

- (void)hideKeyboard:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (indexPath != nil && indexPath.section == 0 && indexPath.row == 0)
    {
        return;
    }
    
    [self.descriptionTextView resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && self.view.window == nil)
    {
        self.view = nil;
    }
    
    if (![self isViewLoaded]) {
        self.descriptionTextView = nil;
        self.categoryLabel = nil;
        self.latitudeLabel = nil;
        self.longitudeLabel = nil;
        self.addressLabel = nil;
        self.dateLabel = nil;
        self.imageView = nil;
        self.photoLabel = nil;
    }
}



- (IBAction)done:(id)sender
{
    //NSLog(@"Description '%@'", descriptionText);
    
    //[self closeScreen];
    HudView *hudView = [HudView hudInView:self.navigationController.view animated:YES];
    
    Location *location = nil;
    
    if (self.locationToEdit != nil)
    {
        hudView.text = @"Updated";
        location = self.locationToEdit;
    }
    else
    {
        hudView.text = @"Tagged";
        location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
        //location.photoId = [NSNumber numberWithInt:-1];
        location.photoId = @-1;
    }
    
    location.locationDescription = descriptionText;
    location.category = categoryName;
    location.latitude = [NSNumber numberWithDouble:self.coordinate.latitude];
    location.longitude = [NSNumber numberWithDouble:self.coordinate.longitude];
    location.date = date;
    location.placemark = self.placemark;
    
    if (image != nil)
    {
        if (![location hasPhoto])
        {
            location.photoId = [NSNumber numberWithInt:[self nextPhotoId]];
        }
        
        NSData *data = UIImagePNGRepresentation(image);
        NSError *error;
        if (![data writeToFile:[location photoPath] options:NSDataWritingAtomic error:&error])
        {
            NSLog(@"Error writing file: %@", error);
        }
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error])
    {
        FATAL_CORE_DATA_ERROR(error);
        //NSLog(@"Error: %@", error);
        //abort();
    }
    
    
    [self performSelector:@selector(closeScreen) withObject:nil afterDelay:0.6];
}

- (int)nextPhotoId
{
    int photoId = [[NSUserDefaults standardUserDefaults] integerForKey:@"PhotoID"];
    [[NSUserDefaults standardUserDefaults] setInteger:photoId+1 forKey:@"PhotoID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return photoId;
}

- (IBAction)cancel:(id)sender
{
    [self closeScreen];
}

- (void)closeScreen
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 0 && indexPath.row == 0)
    {
        [self.descriptionTextView becomeFirstResponder];
    }
    else if (indexPath.section == 1 && indexPath.row == 0)
    {
        [self showPhotoMenu];
    }
}

- (void)takePhoto
{
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)choosePhotoFromLibrary
{
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)showPhotoMenu
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    //if (YES)
    {
        actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:nil
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
        [actionSheet showInView:self.view];
        
    }
    else
    {
        [self choosePhotoFromLibrary];
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)theActionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self takePhoto];
    }
    else if (buttonIndex == 1)
    {
        [self choosePhotoFromLibrary];
    }
    actionSheet = nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1)
    {
        return indexPath;
    }
    else
    {
        return nil;
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if ([self isViewLoaded])
    {
        [self showImage:image];
        [self.tableView reloadData];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    imagePicker = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    imagePicker = nil;
}

- (void)showImage:(UIImage *)theImage
{
    self.imageView.image = theImage;
    self.imageView.hidden = NO;
    self.imageView.frame = CGRectMake(10, 10, 260, 260);
    self.photoLabel.hidden = YES;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        return 88;
    }
    else if (indexPath.section == 1)
    {
        if (self.imageView.hidden)
        {
            return 44;
        }
        else
        {
            return 280;
        }
    }
    else if (indexPath.section == 2 && indexPath.row == 2)
    {
        CGRect rect = CGRectMake(100, 10, 190, 1000);
        self.addressLabel.frame = rect;
        [self.addressLabel sizeToFit];
        
        rect.size.height = self.addressLabel.frame.size.height;
        self.addressLabel.frame = rect;
        
        return self.addressLabel.frame.size.height + 20;
    }
    else
    {
        return 44;
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)theTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    descriptionText = [theTextView.text stringByReplacingCharactersInRange:range withString:text];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)theTextView
{
    descriptionText = theTextView.text;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PickCategory"])
    {
        CategoryPickerViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.selectedCategoryName = categoryName;
    }
}

#pragma mark - CategoryPickerViewControllerDelegate
- (void)categoryPicker:(CategoryPickerViewController *)picker didPickCategory:(NSString *)theCategoryName
{
    categoryName = theCategoryName;
    self.categoryLabel.text = categoryName;
    [self.navigationController popViewControllerAnimated:YES];
}




@end
